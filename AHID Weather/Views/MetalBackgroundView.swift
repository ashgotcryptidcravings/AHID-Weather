import SwiftUI
import Metal
import MetalKit

// MARK: - SwiftUI wrapper (cross-platform)

struct MetalBackgroundView: View {
    var body: some View { _OrbRepresentable() }
}

#if os(macOS)
private struct _OrbRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> OrbMTKView { OrbMTKView() }
    func updateNSView(_ nsView: OrbMTKView, context: Context) {}
}
#else
private struct _OrbRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> OrbMTKView { OrbMTKView() }
    func updateUIView(_ uiView: OrbMTKView, context: Context) {}
}
#endif

// MARK: - MTKView subclass
// MTKView inherits UIView on iOS and NSView on macOS — same render code works on both.

final class OrbMTKView: MTKView {

    private var commandQueue: MTLCommandQueue?
    private var pipeline: MTLRenderPipelineState?

    override init(frame: CGRect, device: MTLDevice?) {
        super.init(frame: frame, device: device ?? MTLCreateSystemDefaultDevice())
        setup()
    }
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        guard let device = self.device else { return }

        clearColor           = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        colorPixelFormat     = .bgra8Unorm
        framebufferOnly      = true
        isPaused             = true       // static; render on demand
        enableSetNeedsDisplay = true

        // Transparency differs by platform: NSView layer is optional, UIView layer is not
        #if os(macOS)
        layer?.isOpaque = false
        #else
        isOpaque        = false
        backgroundColor = .clear
        layer.isOpaque  = false
        #endif

        commandQueue = device.makeCommandQueue()

        guard
            let lib  = device.makeDefaultLibrary(),
            let vert = lib.makeFunction(name: "orbVertex"),
            let frag = lib.makeFunction(name: "orbFragment")
        else { return }

        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction   = vert
        desc.fragmentFunction = frag
        desc.colorAttachments[0].pixelFormat               = colorPixelFormat
        desc.colorAttachments[0].isBlendingEnabled         = true
        desc.colorAttachments[0].sourceRGBBlendFactor      = .one
        desc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        desc.colorAttachments[0].sourceAlphaBlendFactor    = .one
        desc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        pipeline = try? device.makeRenderPipelineState(descriptor: desc)
        setNeedsDisplay(bounds)
    }

    override func draw(_ rect: CGRect) {
        guard
            let pipeline,
            let queue    = commandQueue,
            let drawable = currentDrawable,
            let passDesc = currentRenderPassDescriptor,
            let cmdBuf   = queue.makeCommandBuffer(),
            let encoder  = cmdBuf.makeRenderCommandEncoder(descriptor: passDesc)
        else { return }

        encoder.setRenderPipelineState(pipeline)
        var res = SIMD2<Float>(Float(drawableSize.width), Float(drawableSize.height))
        encoder.setFragmentBytes(&res, length: MemoryLayout<SIMD2<Float>>.size, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
        cmdBuf.present(drawable)
        cmdBuf.commit()
    }
}

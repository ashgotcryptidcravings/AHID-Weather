import SwiftUI
import Metal
import MetalKit

// MARK: - SwiftUI wrapper

struct MetalScanView: View {
    var body: some View { _ScanRepresentable() }
}

#if os(macOS)
private struct _ScanRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> ScanMTKView { ScanMTKView() }
    func updateNSView(_ v: ScanMTKView, context: Context) {}
}
#else
private struct _ScanRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> ScanMTKView { ScanMTKView() }
    func updateUIView(_ v: ScanMTKView, context: Context) {}
}
#endif

// MARK: - MTKView subclass — continuous animation

final class ScanMTKView: MTKView {

    private var commandQueue: MTLCommandQueue?
    private var pipeline: MTLRenderPipelineState?
    private var progress: Float = 0.0

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
        isPaused             = false
        preferredFramesPerSecond = 30

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
            let vert = lib.makeFunction(name: "scanVertex"),
            let frag = lib.makeFunction(name: "scanFragment")
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

        // Advance progress each frame (~30 fps → full sweep in ~1.5 s)
        progress = fmod(progress + 0.022, 1.0)

        encoder.setRenderPipelineState(pipeline)
        var prog = progress
        encoder.setFragmentBytes(&prog, length: MemoryLayout<Float>.size, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
        cmdBuf.present(drawable)
        cmdBuf.commit()
    }
}

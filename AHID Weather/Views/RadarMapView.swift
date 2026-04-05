import SwiftUI
import MapKit

// MARK: - MKMapView wrapper with tile overlay support
struct RadarNSMapView: NSViewRepresentable {
    let center: CLLocationCoordinate2D
    let tileURLTemplate: String?
    let tileOpacity: Double

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> MKMapView {
        let mv = MKMapView()
        mv.delegate = context.coordinator
        mv.appearance = NSAppearance(named: .darkAqua)
        mv.showsCompass = false
        mv.showsScale = false
        let region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 4)
        )
        mv.setRegion(region, animated: false)

        // Location annotation
        let ann = MKPointAnnotation()
        ann.coordinate = center
        mv.addAnnotation(ann)
        context.coordinator.annotation = ann

        return mv
    }

    func updateNSView(_ mv: MKMapView, context: Context) {
        // Update annotation position if center changed
        context.coordinator.annotation?.coordinate = center

        // Swap tile overlay when template changes
        let newTemplate = tileURLTemplate ?? ""
        if context.coordinator.currentTemplate != newTemplate {
            context.coordinator.currentTemplate = newTemplate
            // Remove old overlays
            mv.removeOverlays(mv.overlays)
            context.coordinator.tileRenderer = nil
            // Add new overlay if we have a template
            if !newTemplate.isEmpty {
                let overlay = MKTileOverlay(urlTemplate: newTemplate)
                overlay.canReplaceMapContent = false
                mv.addOverlay(overlay, level: .aboveLabels)
            }
        }

        // Update opacity live if slider changed
        context.coordinator.tileRenderer?.alpha = CGFloat(tileOpacity)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, MKMapViewDelegate {
        var annotation: MKPointAnnotation?
        var currentTemplate: String = ""
        var tileRenderer: MKTileOverlayRenderer?

        func mapView(_ mv: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tile = overlay as? MKTileOverlay {
                let renderer = MKTileOverlayRenderer(tileOverlay: tile)
                // tileOpacity is captured via updateNSView after creation;
                // set an initial value from the stored renderer reference
                renderer.alpha = tileRenderer?.alpha ?? 0.7
                tileRenderer = renderer
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mv: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let id = "ahid-loc"
            let view = mv.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.annotation = annotation
            view.markerTintColor = NSColor(red: 0.659, green: 0.333, blue: 0.969, alpha: 1)
            view.glyphImage = nil
            view.canShowCallout = false
            return view
        }
    }
}

// MARK: - RadarMapView
struct RadarMapView: View {
    @ObservedObject var vm: WeatherViewModel

    @State private var radarFrames: [RadarFrame] = []
    @State private var currentFrameIndex: Int = -1
    @State private var isPlaying: Bool = false
    @State private var radarTimestamp: String = "SOURCE: RAINVIEWER"
    @State private var opacity: Double = 0.7
    @State private var timer: Timer?
    @State private var selectedLayer: RadarLayer = .precipitation

    @AppStorage("apiKey_owm") private var owmKey: String = ""

    // Tile URL for the currently selected layer + frame
    private var tileURLTemplate: String? {
        switch selectedLayer {
        case .precipitation:
            guard !radarFrames.isEmpty, currentFrameIndex >= 0,
                  currentFrameIndex < radarFrames.count else { return nil }
            let path = radarFrames[currentFrameIndex].path
            return "https://tilecache.rainviewer.com\(path)/256/{z}/{x}/{y}/2/1_1.png"
        default:
            guard !owmKey.isEmpty else { return nil }
            return selectedLayer.owmTileTemplate(key: owmKey)
        }
    }

    private var needsOWMKey: Bool {
        !selectedLayer.usesRainViewer && owmKey.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BlockLabel(text: "LIVE PRECIPITATION RADAR")

            // Layer tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(RadarLayer.allCases) { layer in
                        layerPill(layer)
                    }
                }
                .padding(.bottom, 10)
            }

            // Map
            ZStack {
                RadarNSMapView(
                    center: CLLocationCoordinate2D(
                        latitude: vm.locationService.latitude,
                        longitude: vm.locationService.longitude
                    ),
                    tileURLTemplate: tileURLTemplate,
                    tileOpacity: opacity
                )
                .frame(height: 300)

                // OWM key missing overlay
                if needsOWMKey {
                    VStack(spacing: 6) {
                        Text("KEY-OWM")
                            .font(.system(size: 9, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(ThemeColors.accentBright)
                        Text("OpenWeatherMap key required")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(ThemeColors.whiteDim)
                        Text("Add in Settings → API Keys")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(ThemeColors.accent)
                    }
                    .padding(12)
                    .background(ThemeColors.void2.opacity(0.9))
                    .overlay(Rectangle().stroke(ThemeColors.accent.opacity(0.3), lineWidth: 1))
                }
            }
            .overlay(Rectangle().stroke(ThemeColors.accent.opacity(0.1), lineWidth: 1))

            // Controls (only show for PRECIP / RainViewer animation)
            if selectedLayer == .precipitation {
                HStack(spacing: 8) {
                    Button(action: togglePlay) {
                        Text(isPlaying ? "⏸ PAUSE" : "▶ PLAY")
                            .font(.system(size: 9, design: .monospaced))
                            .tracking(1)
                            .foregroundColor(ThemeColors.accentBright)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(isPlaying ? ThemeColors.accentDim : ThemeColors.void3)
                            .overlay(Rectangle().stroke(ThemeColors.accent.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Button(action: resetToLive) {
                        Text("⟳ LIVE")
                            .font(.system(size: 9, design: .monospaced))
                            .tracking(1)
                            .foregroundColor(ThemeColors.accentBright)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(ThemeColors.void3)
                            .overlay(Rectangle().stroke(ThemeColors.accent.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(radarTimestamp)
                        .font(.system(size: 8, design: .monospaced))
                        .tracking(1)
                        .foregroundColor(ThemeColors.white.opacity(0.3))
                }
                .padding(.top, 10)
            }

            // Opacity slider (all layers)
            HStack(spacing: 8) {
                Text("OVERLAY OPACITY")
                    .font(.system(size: 8, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(ThemeColors.whiteDim)

                Slider(value: $opacity, in: 0.2...1.0)
                    .frame(width: 120)

                Text(String(format: "%.0f%%", opacity * 100))
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(ThemeColors.whiteDim)
                    .frame(width: 30, alignment: .leading)
            }
            .padding(.top, selectedLayer == .precipitation ? 8 : 10)
        }
        .panelStyle()
        .task { await loadRadarFrames() }
    }

    // MARK: - Layer Pill
    private func layerPill(_ layer: RadarLayer) -> some View {
        let active = selectedLayer == layer
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedLayer = layer
                if layer == .precipitation && !radarFrames.isEmpty {
                    currentFrameIndex = radarFrames.count - 1
                    updateTimestamp()
                }
            }
        }) {
            HStack(spacing: 4) {
                Text(layer.icon).font(.system(size: 10))
                Text(layer.label)
                    .font(.system(size: 7.5, design: .monospaced))
                    .tracking(1)
                if !layer.usesRainViewer && owmKey.isEmpty {
                    Text("KEY")
                        .font(.system(size: 6, design: .monospaced))
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(Color.orange.opacity(0.3))
                        .foregroundColor(.orange)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(active ? ThemeColors.accent.opacity(0.55) : Color.black.opacity(0.5))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(
                    active ? ThemeColors.accentBright : ThemeColors.accent.opacity(0.25),
                    lineWidth: 1
                )
            )
            .foregroundColor(active ? .white : ThemeColors.whiteDim)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Radar Animation
    private func loadRadarFrames() async {
        guard let url = URL(string: "https://api.rainviewer.com/public/weather-maps.json") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(RainViewerResponse.self, from: data)
            radarFrames = response.radar.past + (response.radar.nowcast ?? [])
            currentFrameIndex = radarFrames.count - 1
            updateTimestamp()
        } catch {
            radarTimestamp = "[\(AppError.wx002_networkTimeout.code)] RADAR UNAVAILABLE"
        }
    }

    private func togglePlay() {
        if isPlaying {
            isPlaying = false
            timer?.invalidate()
            timer = nil
        } else {
            isPlaying = true
            currentFrameIndex = 0
            timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
                currentFrameIndex = (currentFrameIndex + 1) % max(radarFrames.count, 1)
                updateTimestamp()
            }
        }
    }

    private func resetToLive() {
        if isPlaying { togglePlay() }
        currentFrameIndex = radarFrames.count - 1
        updateTimestamp()
    }

    private func updateTimestamp() {
        guard currentFrameIndex >= 0, currentFrameIndex < radarFrames.count else { return }
        let frame = radarFrames[currentFrameIndex]
        let f = DateFormatter(); f.dateFormat = "h:mm a"
        radarTimestamp = "\(f.string(from: Date(timeIntervalSince1970: TimeInterval(frame.time)))) · RAINVIEWER · \(currentFrameIndex + 1)/\(radarFrames.count)"
    }
}

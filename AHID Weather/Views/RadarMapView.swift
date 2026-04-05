import SwiftUI
import MapKit

struct RadarMapView: View {
    @ObservedObject var vm: WeatherViewModel
    @State private var radarFrames: [RadarFrame] = []
    @State private var currentFrameIndex: Int = -1
    @State private var isPlaying: Bool = false
    @State private var radarTimestamp: String = "SOURCE: RAINVIEWER"
    @State private var opacity: Double = 0.7
    @State private var timer: Timer?

    @State private var region: MKCoordinateRegion

    init(vm: WeatherViewModel) {
        self._vm = ObservedObject(wrappedValue: vm)
        self._region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: vm.locationService.latitude, longitude: vm.locationService.longitude),
            span: MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 4)
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BlockLabel(text: "LIVE PRECIPITATION RADAR")

            // Map
            Map(coordinateRegion: $region, annotationItems: [LocationAnnotation(coordinate: CLLocationCoordinate2D(latitude: vm.locationService.latitude, longitude: vm.locationService.longitude))]) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    Circle()
                        .fill(ThemeColors.accent)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(ThemeColors.accentBright, lineWidth: 2))
                }
            }
            .frame(height: 320)
            .colorScheme(.dark)
            .overlay(
                Rectangle()
                    .stroke(ThemeColors.accent.opacity(0.1), lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                // Layer pills
                HStack(spacing: 5) {
                    layerPill(icon: "🌧", label: "PRECIP", active: true)
                    layerPill(icon: "🌡", label: "TEMP", active: false)
                    layerPill(icon: "💨", label: "WIND", active: false)
                    layerPill(icon: "☁", label: "CLOUDS", active: false)
                    layerPill(icon: "◎", label: "PRESSURE", active: false)
                }
                .padding(8)
            }

            // Controls
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

                HStack(spacing: 8) {
                    Text("OPACITY")
                        .font(.system(size: 8, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(ThemeColors.whiteDim)

                    Slider(value: $opacity, in: 0.2...1.0)
                        .frame(width: 100)
                        .tint(ThemeColors.accentBright)
                }

                Spacer()

                Text(radarTimestamp)
                    .font(.system(size: 8, design: .monospaced))
                    .tracking(1)
                    .foregroundColor(ThemeColors.white.opacity(0.3))
            }
            .padding(.top, 10)
        }
        .panelStyle()
        .task { await loadRadarFrames() }
    }

    private func layerPill(icon: String, label: String, active: Bool) -> some View {
        HStack(spacing: 4) {
            Text(icon).font(.system(size: 10))
            Text(label)
                .font(.system(size: 7.5, design: .monospaced))
                .tracking(1)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            active ? ThemeColors.accent.opacity(0.55) : Color.black.opacity(0.75)
        )
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(
                active ? ThemeColors.accentBright : ThemeColors.accent.opacity(0.25),
                lineWidth: 1
            )
        )
        .foregroundColor(active ? .white : ThemeColors.whiteDim)
    }

    private func loadRadarFrames() async {
        guard let url = URL(string: "https://api.rainviewer.com/public/weather-maps.json") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(RainViewerResponse.self, from: data)
            radarFrames = response.radar.past + (response.radar.nowcast ?? [])
            currentFrameIndex = radarFrames.count - 1
            updateTimestamp()
        } catch {
            radarTimestamp = "RADAR UNAVAILABLE"
            print("[AHID] Radar error: \(error.localizedDescription)")
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
        let date = Date(timeIntervalSince1970: TimeInterval(frame.time))
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        radarTimestamp = "\(formatter.string(from: date)) · RAINVIEWER · \(currentFrameIndex + 1)/\(radarFrames.count)"
    }
}

struct LocationAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

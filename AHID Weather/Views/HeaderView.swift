import SwiftUI

struct HeaderView: View {
    @ObservedObject var vm: WeatherViewModel
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // Clock
            HStack {
                Spacer()
                Text(formattedTime)
                    .font(.system(.caption, design: .default).weight(.light))
                    .tracking(2)
                    .foregroundColor(ThemeColors.white.opacity(0.3))
                    .monospacedDigit()
            }
            .padding(.bottom, 8)

            // Header bar
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 0) {
                        Text("AHID ")
                            .font(.system(size: 11, weight: .bold, design: .default))
                            .tracking(3)
                            .foregroundColor(ThemeColors.accentBright)
                        Text("// WEATHER SYSTEM")
                            .font(.system(size: 11, weight: .light, design: .default))
                            .tracking(3)
                            .foregroundColor(ThemeColors.whiteDim)
                    }
                    Text(vm.lastUpdated)
                        .font(.system(size: 9, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(ThemeColors.white.opacity(0.3))
                }

                Spacer()

                HStack(spacing: 16) {
                    // Status
                    HStack(spacing: 8) {
                        Circle()
                            .fill(ThemeColors.accentBright)
                            .frame(width: 6, height: 6)
                            .shadow(color: ThemeColors.accent.opacity(0.4), radius: 4)

                        Text("LIVE")
                            .font(.system(size: 10, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(ThemeColors.whiteDim)

                        Text("|")
                            .foregroundColor(ThemeColors.accent.opacity(0.5))

                        Text(vm.coordDisplay)
                            .font(.system(size: 10, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(ThemeColors.whiteDim)
                    }
                }
            }
            .padding(.bottom, 16)

            Divider()
                .background(ThemeColors.accent.opacity(0.3))
        }
        .onReceive(timer) { self.currentTime = $0 }
    }

    private static let clockFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d  HH:mm:ss"
        return f
    }()

    private var formattedTime: String {
        Self.clockFormatter.string(from: currentTime).uppercased()
    }
}

// MARK: - Location Block
struct LocationBlockView: View {
    @ObservedObject var vm: WeatherViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(vm.locationService.city)
                .font(.system(size: 42, weight: .bold, design: .default))
                .foregroundColor(ThemeColors.white)

            Text(locationMeta)
                .font(.system(size: 10, design: .monospaced))
                .tracking(3)
                .foregroundColor(ThemeColors.whiteDim)
                .textCase(.uppercase)
        }
        .padding(.bottom, 8)
    }

    private var locationMeta: String {
        if vm.locationService.usedFallback {
            return "\(vm.locationService.meta) · ZIP 43607"
        }
        let lat = vm.locationService.latitude
        let lon = vm.locationService.longitude
        return "\(vm.locationService.meta) · \(String(format: "%.4f", lat))°N \(String(format: "%.4f", abs(lon)))°\(lon < 0 ? "W" : "E")"
    }
}

// MARK: - Section Header (collapsible toggle)
struct SectionHeader: View {
    let title: String
    @Binding var isCollapsed: Bool

    var body: some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.3)) { isCollapsed.toggle() } }) {
            HStack {
                Text(title)
                    .font(.system(size: 9, design: .monospaced))
                    .tracking(4)
                    .foregroundColor(ThemeColors.accentBright)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(ThemeColors.accentBright)
                    .rotationEffect(.degrees(isCollapsed ? -90 : 0))
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(ThemeColors.accent.opacity(0.12))
                .frame(height: 1)
        }
    }
}

// MARK: - Panel Style
struct PanelModifier: ViewModifier {
    var highlight: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(ThemeColors.void2)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(highlight ? ThemeColors.accentBright : ThemeColors.panelBorder, lineWidth: 1)
            )
    }
}

extension View {
    func panelStyle(highlight: Bool = false) -> some View {
        modifier(PanelModifier(highlight: highlight))
    }
}

// MARK: - Block Label
struct BlockLabel: View {
    let text: String
    var hint: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            Text(text)
                .font(.system(size: 9, design: .monospaced))
                .tracking(4)
                .foregroundColor(ThemeColors.accentBright)

            Rectangle()
                .fill(ThemeColors.accent.opacity(0.3))
                .frame(height: 1)

            if let hint = hint {
                Text("// \(hint)")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(ThemeColors.white.opacity(0.15))
            }
        }
        .padding(.bottom, 12)
    }
}

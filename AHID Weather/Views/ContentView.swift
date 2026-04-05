import SwiftUI

struct ContentView: View {
    @StateObject private var vm = WeatherViewModel()

    // Collapsible section state
    @State private var conditionsCollapsed = false
    @State private var alertsCollapsed = false
    @State private var metricsCollapsed = false
    @State private var hourlyCollapsed = false
    @State private var radarCollapsed = false
    @State private var aiCollapsed = false

    var body: some View {
        ZStack {
            // Background
            ThemeColors.void0
                .ignoresSafeArea()

            // Background orbs (decorative)
            backgroundOrbs

            if vm.isLoading {
                loadingScreen
            } else {
                mainContent
            }
        }
        .task {
            await vm.start()
        }
    }

    // MARK: - Loading Screen
    private var loadingScreen: some View {
        VStack(spacing: 20) {
            Text("AHID // ADMINISTRATIVE HUMAN INTERFACE DESIGN")
                .font(.system(size: 11, weight: .light, design: .default))
                .tracking(5)
                .foregroundColor(ThemeColors.accent.opacity(0.4))

            Text(vm.loadingMessage)
                .font(.system(size: 11, design: .monospaced))
                .tracking(5)
                .foregroundColor(ThemeColors.accentBright)

            // Loading bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(ThemeColors.void4)
                        .frame(height: 1)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, ThemeColors.accentBright, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width, height: 1)
                        .modifier(ScanAnimation())
                }
            }
            .frame(width: 200, height: 1)
        }
    }

    // MARK: - Main Content
    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                topSections
                bottomSections
                footerSection
            }
            .padding(24)
        }
        .background(ThemeColors.void0)
    }

    @ViewBuilder
    private var topSections: some View {
        HeaderView(vm: vm)
        LocationBlockView(vm: vm)

        if let error = vm.errorMessage {
            Text("DATA ERROR: \(error)")
                .font(.system(size: 10, design: .monospaced))
                .tracking(1)
                .foregroundColor(.red)
                .padding(12)
                .background(Color.red.opacity(0.1))
                .overlay(Rectangle().stroke(Color.red.opacity(0.3), lineWidth: 1))
        }

        if vm.showConditions {
            SectionHeader(title: "CURRENT CONDITIONS", isCollapsed: $conditionsCollapsed)
            if !conditionsCollapsed {
                CurrentConditionsView(vm: vm).transition(.opacity)
            }
        }

        if vm.showAlerts {
            SectionHeader(title: "WEATHER ALERTS", isCollapsed: $alertsCollapsed)
            if !alertsCollapsed {
                AlertsView(alerts: vm.alerts).transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private var bottomSections: some View {
        if vm.showMetrics {
            SectionHeader(title: "DATA METRICS", isCollapsed: $metricsCollapsed)
            if !metricsCollapsed {
                MetricsGridView(vm: vm).transition(.opacity)
            }
        }

        if vm.showHourly {
            SectionHeader(title: "24-HOUR FORECAST", isCollapsed: $hourlyCollapsed)
            if !hourlyCollapsed {
                HourlyForecastView(items: vm.hourlyItems).transition(.opacity)
            }
        }

        if vm.showRadar {
            SectionHeader(title: "RADAR & 7-DAY FORECAST", isCollapsed: $radarCollapsed)
            if !radarCollapsed {
                HStack(alignment: .top, spacing: 16) {
                    RadarMapView(vm: vm).frame(maxWidth: .infinity)
                    ForecastView(vm: vm).frame(maxWidth: .infinity)
                }
                .transition(.opacity)
            }
        }

        if vm.showAI {
            SectionHeader(title: "AI ASSISTANT", isCollapsed: $aiCollapsed)
            if !aiCollapsed {
                AIChatView(vm: vm).transition(.opacity)
            }
        }
    }

    private var footerSection: some View {
        VStack(spacing: 0) {
            Text(vm.quote)
                .font(.system(size: 12, weight: .light, design: .default))
                .italic()
                .foregroundColor(ThemeColors.white.opacity(0.2))
                .tracking(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)

            HStack {
                Text("AHID // WEATHER SYSTEM · OPEN-METEO + RAINVIEWER + AI")
                    .font(.system(size: 9, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(ThemeColors.whiteDim)
                Spacer()
                Text("A ZZZerosworld INTERFACE")
                    .font(.system(size: 9, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(ThemeColors.accentBright)
            }
            .padding(.top, 16)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(ThemeColors.accent.opacity(0.2))
                    .frame(height: 1)
            }
        }
    }

    // MARK: - Background Orbs
    private var backgroundOrbs: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.486, green: 0.227, blue: 0.929).opacity(0.04))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -100, y: -200)

            Circle()
                .fill(Color(red: 0.659, green: 0.333, blue: 0.969).opacity(0.03))
                .frame(width: 250, height: 250)
                .blur(radius: 80)
                .offset(x: 200, y: 100)

            Circle()
                .fill(Color.blue.opacity(0.02))
                .frame(width: 350, height: 350)
                .blur(radius: 80)
                .offset(x: -50, y: 300)
        }
    }
}

// MARK: - Scan Animation
struct ScanAnimation: ViewModifier {
    @State private var offset: CGFloat = -200

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    offset = 200
                }
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

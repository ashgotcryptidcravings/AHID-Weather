import SwiftUI

struct ContentView: View {
    @StateObject private var vm = WeatherViewModel()

    @State private var conditionsCollapsed = false
    @State private var alertsCollapsed = false
    @State private var metricsCollapsed = false
    @State private var hourlyCollapsed = false
    @State private var radarCollapsed = false
    @State private var aiCollapsed = false

    #if os(iOS)
    @State private var showSettings = false
    #endif

    var body: some View {
        ZStack {
            // Background fills edge-to-edge under Dynamic Island and home indicator.
            // Each background layer carries its own .ignoresSafeArea(); the ZStack
            // itself does NOT suppress safe areas so the ScrollView gets proper insets.
            ThemeColors.void0.ignoresSafeArea()
            backgroundOrbs

            if vm.isLoading {
                loadingScreen
            } else {
                mainContent
            }
        }
        // ZStack fills the full screen (including under Dynamic Island + home indicator).
        // ScrollView automatically inserts content insets matching safe area, so content
        // never renders behind the Dynamic Island or home indicator.
        .ignoresSafeArea()
        .task { await vm.start() }
        #if os(iOS)
        .overlay(alignment: .bottomTrailing) {
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16))
                    .foregroundColor(ThemeColors.accentBright)
                    .padding(14)
                    .background(ThemeColors.void2)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(ThemeColors.accent.opacity(0.4), lineWidth: 1))
            }
            .padding(.bottom, 16)
            .padding(.trailing, 20)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        #endif
    }

    // MARK: - Loading Screen (Metal scan bar)

    private var loadingScreen: some View {
        VStack(spacing: 20) {
            Text("AHID // ADMINISTRATIVE HUMAN INTERFACE DESIGN")
                .font(.system(size: 11, weight: .light))
                .tracking(5)
                .foregroundColor(ThemeColors.accent.opacity(0.4))

            Text(vm.loadingMessage)
                .font(.system(size: 11, design: .monospaced))
                .tracking(5)
                .foregroundColor(ThemeColors.accentBright)

            // Metal-rendered scan line
            ZStack {
                Rectangle()
                    .fill(ThemeColors.void4)
                    .frame(height: 2)
                MetalScanView()
                    .frame(height: 4)
            }
            .frame(width: 200)
            .clipShape(Rectangle())
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
            #if os(iOS)
            // Extra bottom padding clears the gear button (safe area handles home indicator)
            .padding(.bottom, 72)
            #endif
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
                #if os(iOS)
                VStack(spacing: 16) {
                    RadarMapView(vm: vm)
                    ForecastView(vm: vm)
                }
                .transition(.opacity)
                #else
                HStack(alignment: .top, spacing: 16) {
                    RadarMapView(vm: vm).frame(maxWidth: .infinity)
                    ForecastView(vm: vm).frame(maxWidth: .infinity)
                }
                .transition(.opacity)
                #endif
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
                .font(.system(size: 12, weight: .light))
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

    // MARK: - Background Orbs (Metal)

    private var backgroundOrbs: some View {
        MetalBackgroundView()
            .allowsHitTesting(false)
            .ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView() }
}

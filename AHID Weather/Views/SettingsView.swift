import SwiftUI
import WebKit
#if os(iOS)
import ActivityKit
#endif

private extension Color {
    static var settingsCardBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.secondarySystemBackground).opacity(0.6)
        #else
        return Color(NSColor.controlBackgroundColor).opacity(0.6)
        #endif
    }
}

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General",   systemImage: "gearshape") }
            APIKeysSettingsView()
                .tabItem { Label("API Keys",  systemImage: "key") }
            WidgetSettingsView()
                .tabItem { Label("Widgets",   systemImage: "square.grid.2x2") }
            LocationSimulationView()
                .tabItem { Label("Location",  systemImage: "mappin.and.ellipse") }
            HealthInfoView()
                .tabItem { Label("Health",    systemImage: "heart.text.square") }
            ChangelogView()
                .tabItem { Label("Changelog", systemImage: "clock.arrow.circlepath") }
            DebugView()
                .tabItem { Label("Debug",     systemImage: "ladybug") }
            #if os(iOS)
            DynamicIslandDebugView()
                .tabItem { Label("D.Island",  systemImage: "dot.circle.and.hand.point.up.left.fill") }
            #endif
        }
        #if os(macOS)
        .frame(width: 580, height: 520)
        #endif
    }
}

// MARK: - General Settings
struct GeneralSettingsView: View {
    @AppStorage("useCelsius")         private var useCelsius         = false
    @AppStorage("autoRefreshEnabled") private var autoRefreshEnabled = true
    @AppStorage("refreshIntervalMin") private var refreshIntervalMin = 10
    @AppStorage("aiTimeoutSeconds")   private var aiTimeoutSeconds: Double = 12
    @AppStorage("aiMaxTokens")        private var aiMaxTokens        = 300
    @AppStorage("verboseLogging")     private var verboseLogging      = false
    @AppStorage("errorSoundEnabled")  private var errorSoundEnabled  = true
    @AppStorage("errorNotifEnabled")  private var errorNotifEnabled  = true

    private let intervalOptions = [5, 10, 15, 30]
    private let timeoutOptions: [Double] = [8, 12, 20, 30]
    private let tokenOptions = [100, 200, 300, 500]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("General Settings").font(.headline)

                // Temperature
                settingsCard {
                    label("TEMPERATURE UNIT")
                    Toggle("Use Celsius (°C)", isOn: $useCelsius).toggleStyle(.switch)
                }

                // Auto-refresh
                settingsCard {
                    label("AUTO-REFRESH")
                    Toggle("Enable background refresh", isOn: $autoRefreshEnabled).toggleStyle(.switch)
                    if autoRefreshEnabled {
                        HStack {
                            Text("Interval").font(.callout)
                            Spacer()
                            Picker("", selection: $refreshIntervalMin) {
                                ForEach(intervalOptions, id: \.self) { m in
                                    Text("\(m) min").tag(m)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 200)
                        }
                        .padding(.top, 4)
                        Text("Restart app for interval change to take effect.")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }

                // AI Behavior
                settingsCard {
                    label("AI BEHAVIOR")
                    HStack {
                        Text("Request timeout").font(.callout)
                        Spacer()
                        Picker("", selection: $aiTimeoutSeconds) {
                            ForEach(timeoutOptions, id: \.self) { t in
                                Text("\(Int(t))s").tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 200)
                    }
                    HStack {
                        Text("Max tokens").font(.callout)
                        Spacer()
                        Picker("", selection: $aiMaxTokens) {
                            ForEach(tokenOptions, id: \.self) { t in
                                Text("\(t)").tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 200)
                    }
                    Text("AI responses only come from the API. No offline fallback — failed calls show an error code.")
                        .font(.caption2).foregroundColor(.secondary)
                }

                // Error Alerts
                settingsCard {
                    label("ERROR ALERTS")
                    Toggle("Play sound on error", isOn: $errorSoundEnabled).toggleStyle(.switch)
                    Toggle("Show notification on error", isOn: $errorNotifEnabled).toggleStyle(.switch)
                    Text("Plays a system alert and posts a local notification whenever a weather data fetch fails. Notification permission is requested at launch.")
                        .font(.caption2).foregroundColor(.secondary)
                        .padding(.top, 2)
                }

                // Debug
                settingsCard {
                    label("DEVELOPER")
                    Toggle("Verbose logging (console)", isOn: $verboseLogging).toggleStyle(.switch)
                }

                Text("Theme colors and radar overlay settings are configured directly in the main app panels.")
                    .font(.caption).foregroundColor(.secondary)

                Spacer()
            }
            .padding(24)
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .tracking(2).foregroundColor(.secondary)
            .padding(.bottom, 2)
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .padding(12)
        .background(Color.settingsCardBackground)
        .cornerRadius(8)
    }
}

// MARK: - API Keys Settings
struct APIKeysSettingsView: View {
    @AppStorage("apiKey_anthropic") private var anthropicKey = ""
    @AppStorage("apiKey_gemini")    private var geminiKey    = ""
    @AppStorage("apiKey_openai")    private var openaiKey    = ""
    @AppStorage("apiKey_owm")       private var owmKey       = ""
    @State private var showKeys    = false
    @State private var testResults: [String: (Bool, String)] = [:]
    @State private var testingKey: String? = nil

    private let testService = AIService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("API Keys").font(.headline)
                Text("Keys are stored in UserDefaults. For production, consider Keychain storage.")
                    .font(.caption).foregroundColor(.secondary)
                Toggle("Show Keys", isOn: $showKeys).toggleStyle(.switch).padding(.bottom, 4)

                Group {
                    keySection(id: "owm",      name: "OPENWEATHERMAP",    badge: "MAP TILES",
                               desc: "Unlocks radar overlay layers — temp, wind, clouds, pressure.",
                               key: $owmKey,       placeholder: "your-owm-key", provider: .owm)
                    keySection(id: "anthropic", name: "ANTHROPIC (CLAUDE)", badge: "AI · PRIMARY",
                               desc: "Claude powers AI chat and forecast analysis.",
                               key: $anthropicKey, placeholder: "sk-ant-...",   provider: .anthropic)
                    keySection(id: "gemini",    name: "GOOGLE GEMINI",     badge: "AI · FALLBACK 1",
                               desc: "Gemini Flash — fast with a generous free tier.",
                               key: $geminiKey,    placeholder: "AIza...",       provider: .gemini)
                    keySection(id: "openai",    name: "OPENAI (GPT)",      badge: "AI · FALLBACK 2",
                               desc: "GPT-4o-mini as secondary AI fallback.",
                               key: $openaiKey,    placeholder: "sk-...",        provider: .openai)
                }

                Button("Clear All Keys") {
                    anthropicKey = ""; geminiKey = ""; openaiKey = ""; owmKey = ""
                    testResults = [:]
                }
                .foregroundColor(.red)
                .padding(.top, 8)
            }
            .padding(24)
        }
    }

    private func keySection(id: String, name: String, badge: String, desc: String,
                            key: Binding<String>, placeholder: String, provider: AIProvider) -> some View {
        let result = testResults[id]
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                Text(badge)
                    .font(.system(size: 8))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(key.wrappedValue.isEmpty ? Color.yellow.opacity(0.15) : Color.green.opacity(0.15))
                    .foregroundColor(key.wrappedValue.isEmpty ? .yellow : .green)
                    .clipShape(Capsule())
                Spacer()
                if !key.wrappedValue.isEmpty {
                    Button(action: { runTest(id: id, key: key.wrappedValue, provider: provider) }) {
                        Group {
                            if testingKey == id {
                                Text("TESTING…").foregroundColor(.orange)
                            } else if let (ok, _) = result {
                                Text(ok ? "✓ PASS" : "✗ FAIL").foregroundColor(ok ? .green : .red)
                            } else {
                                Text("TEST KEY").foregroundColor(.accentColor)
                            }
                        }
                        .font(.system(size: 8, design: .monospaced))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .overlay(Rectangle().stroke(
                        result.map { $0.0 ? Color.green : Color.red } ?? Color.accentColor.opacity(0.4),
                        lineWidth: 1
                    ))
                    .disabled(testingKey == id)
                }
            }

            Text(desc).font(.caption).foregroundColor(.secondary)

            if let (ok, msg) = result {
                Text(msg)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(ok ? .green : .red)
                    .padding(.vertical, 2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if showKeys {
                TextField(placeholder, text: key)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
            } else {
                SecureField(placeholder, text: key)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
            }
        }
        .padding(12)
        .background(Color.settingsCardBackground)
        .cornerRadius(8)
    }

    private func runTest(id: String, key: String, provider: AIProvider) {
        testingKey = id
        testResults.removeValue(forKey: id)
        Task {
            let result = await testService.testKey(provider: provider, key: key)
            await MainActor.run {
                testResults[id] = result
                testingKey = nil
            }
        }
    }
}

// MARK: - Widget Settings
struct WidgetSettingsView: View {
    @AppStorage("showConditions") private var showConditions = true
    @AppStorage("showAlerts")     private var showAlerts     = true
    @AppStorage("showMetrics")    private var showMetrics    = true
    @AppStorage("showHourly")     private var showHourly     = true
    @AppStorage("showRadar")      private var showRadar      = true
    @AppStorage("showAI")         private var showAI         = true

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Visible Sections").font(.headline)
            Text("Toggle which panels are shown in the main view.")
                .font(.caption).foregroundColor(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                widgetToggle("Current Conditions", isOn: $showConditions)
                widgetToggle("Weather Alerts",      isOn: $showAlerts)
                widgetToggle("Data Metrics",         isOn: $showMetrics)
                widgetToggle("24-Hour Forecast",     isOn: $showHourly)
                widgetToggle("Radar & 7-Day",        isOn: $showRadar)
                widgetToggle("AI Assistant",         isOn: $showAI)
            }
            Spacer()
        }
        .padding(24)
    }

    private func widgetToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label).font(.callout)
            Spacer()
            Toggle("", isOn: isOn).toggleStyle(.switch)
        }
        .padding(10)
        .background(Color.settingsCardBackground)
        .cornerRadius(6)
    }
}

// MARK: - Location Simulation
struct LocationSimulationView: View {
    @AppStorage("isSimulatingLocation") private var isSimulating = false
    @AppStorage("simulatedLat")         private var simLat       = "40.7128"
    @AppStorage("simulatedLon")         private var simLon       = "-74.0060"

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Location Simulation").font(.headline)
            Toggle("Enable Manual Coordinates", isOn: $isSimulating).toggleStyle(.switch)
            Text("Bypasses system GPS. Useful when location services are restricted or to preview another city.")
                .font(.caption).foregroundColor(.secondary)
            VStack(spacing: 10) {
                HStack {
                    Text("Latitude").font(.callout).frame(width: 80, alignment: .leading)
                    TextField("e.g. 40.7128", text: $simLat).textFieldStyle(.roundedBorder)
                }
                HStack {
                    Text("Longitude").font(.callout).frame(width: 80, alignment: .leading)
                    TextField("e.g. -74.0060", text: $simLon).textFieldStyle(.roundedBorder)
                }
            }
            .disabled(!isSimulating).opacity(isSimulating ? 1.0 : 0.4)
            if isSimulating {
                Text("LOC-SIM active. Changes apply on next refresh.")
                    .font(.caption2).foregroundColor(.accentColor)
            }
            Spacer()
        }
        .padding(24)
    }
}

// MARK: - Health Info
struct HealthInfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("How Weather Affects You").font(.headline).padding(.bottom, 16)
                healthItem("UV INDEX",
                    "UV damages skin DNA. UV 3+ causes sunburn in 30 min (fair skin). UV 8+ in under 10 min. Cumulative exposure raises melanoma risk.")
                healthItem("AIR QUALITY (PM2.5)",
                    "PM2.5 penetrates deep lung tissue and enters the bloodstream. AQI 100+ triggers airway inflammation. Long-term exposure >50 correlates with cardiovascular disease.")
                healthItem("HUMIDITY",
                    "Below 30% dries mucous membranes, raising infection risk. Above 60% impairs sweat evaporation. Mold thrives >70%, triggering allergies.")
                healthItem("HEAT INDEX",
                    "Above 90°F: heat cramps. Above 105°F: heat exhaustion. Above 130°F: heat stroke. Hydrate aggressively.")
                healthItem("WIND CHILL",
                    "At 0°F with 15 mph wind, frostbite risk in 30 min. Hypothermia begins when core temp drops below 95°F.")
                healthItem("BAROMETRIC PRESSURE",
                    "Rapid drops (>6 hPa in 3 hrs) trigger migraines in susceptible individuals. Low pressure expands joint fluid, worsening arthritis.")
                healthItem("DEW POINT",
                    "Below 55°F: comfortable. 55–65°F: noticeable. Above 65°F: oppressive. Above 70°F: dangerous for sustained exertion.")
                healthItem("PRESSURE TREND",
                    "Rapidly falling pressure (⬇) often precedes storms within 6 hours. Rapidly rising (⬆) signals clearing. Useful for short-range forecasting.")
            }
            .padding(24)
        }
    }

    private func healthItem(_ metric: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(metric)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(2).foregroundColor(.accentColor)
            Text(text).font(.callout).foregroundColor(.secondary).lineSpacing(4)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) { Divider() }
    }
}

// MARK: - Changelog
struct ChangelogView: View {
    private struct Entry {
        let version: String
        let date: String
        let notes: [String]
    }

    private let entries: [Entry] = [
        Entry(version: "2.1", date: "April 2026", notes: [
            "Error sound & notification — system alert plays and a local notification fires whenever a weather data fetch fails",
            "New Settings → General: Error Alerts section with toggles for sound and notification independently",
            "Notification permission requested once at app launch; re-uses the same notification slot per error code to avoid stacking",
            "New error codes: NOTIF-001 (permission denied), NOTIF-002 (notification post failed)",
            "Debug panel Error Code Reference updated with NOTIF-001 and NOTIF-002"
        ]),
        Entry(version: "2.0", date: "April 2026", notes: [
            "Radar layer tabs now functional — PRECIP uses RainViewer tiles; TEMP/WIND/CLOUDS/PRESSURE use OWM tile overlays (key required)",
            "Hourly forecast cards tap-to-expand: shows feels-like, humidity, wind direction, Beaufort scale, and condition",
            "API key testing tool — TEST KEY button per provider with pass/fail and error code",
            "Full AppError system: every failure produces a code (WX-001…WX-005, LOC-001…LOC-004, AI-001…AI-005, KEY-001…KEY-004)",
            "Pressure trend indicator with directional symbol, label, and storm/clearing note",
            "Equal-height condition panels via PreferenceKey — no more uneven layout",
            "Feels-like context label (HOT FEEL / COLD FEEL / NEAR ACTUAL)",
            "Dew point comfort labeling (DRY / COMFORTABLE / PLEASANT / HUMID / OPPRESSIVE)",
            "Hourly API now fetches feels-like, humidity, wind direction, and surface pressure per hour",
            "WeatherKit entitlement confirmed present; Open-Meteo remains primary (WeatherKit availability depends on OS/API support)",
            "iOS + macOS compatibility maintained, including Xcode 14.2 toolchains"
        ]),
        Entry(version: "1.0", date: "April 2026", notes: [
            "Initial release — Open-Meteo weather, RainViewer radar map, AI chat (Claude / Gemini / GPT)",
            "7-day forecast with AI analysis, weather alerts, data metrics grid, UV and AQI panels",
            "Location services with CLGeocoder + Nominatim fallback, location simulation mode",
            "Dark terminal-aesthetic UI with collapsible sections and purple accent theme"
        ])
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Changelog").font(.headline).padding(.bottom, 4)
                ForEach(entries, id: \.version) { entry in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Text("v\(entry.version)")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.accentColor)
                            Text(entry.date)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        ForEach(entry.notes, id: \.self) { note in
                            HStack(alignment: .top, spacing: 8) {
                                Text("·")
                                    .foregroundColor(.accentColor)
                                    .font(.system(size: 11, design: .monospaced))
                                Text(note)
                                    .font(.system(size: 11))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.settingsCardBackground)
                    .cornerRadius(8)
                }
            }
            .padding(24)
        }
    }
}

// MARK: - Debug
struct DebugView: View {
    @State private var cacheCleared = false
    @State private var chatCleared  = false

    @AppStorage("verboseLogging")     private var verboseLogging     = false
    @AppStorage("autoRefreshEnabled") private var autoRefreshEnabled = true
    @AppStorage("refreshIntervalMin") private var refreshIntervalMin = 10
    @AppStorage("aiTimeoutSeconds")   private var aiTimeoutSeconds: Double = 12

    // Access to ViewModel for chat clear — injected via environment or direct call
    // We use NotificationCenter as a lightweight bridge
    private let clearChatNotification = Notification.Name("AHID.clearChat")

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {

                Text("Device & Session Info").font(.headline)
                VStack(spacing: 8) {
                    infoRow("OS Version",  ProcessInfo.processInfo.operatingSystemVersionString)
                    infoRow("App Version", Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0")
                    infoRow("Build",       Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "2")
                    infoRow("Bundle ID",   Bundle.main.bundleIdentifier ?? "—")
                    infoRow("WeatherKit",  weatherKitStatus())
                    infoRow("Auto-Refresh", autoRefreshEnabled ? "ON · \(refreshIntervalMin)min" : "OFF")
                    infoRow("AI Timeout",  "\(Int(aiTimeoutSeconds))s")
                    infoRow("Verbose Log", verboseLogging ? "ON" : "OFF")
                }
                .font(.callout)

                Divider()

                Text("Cache & Data Controls").font(.headline)
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Clear Weather Cache").font(.subheadline)
                            Text("Forces a fresh fetch on next refresh.").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: {
                            clearWebKitCache()
                            cacheCleared = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { cacheCleared = false }
                        }) {
                            Text(cacheCleared ? "Cleared ✓" : "Clear Cache")
                        }
                        .disabled(cacheCleared)
                    }

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Clear Chat History").font(.subheadline)
                            Text("Removes all AI conversation messages.").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: {
                            NotificationCenter.default.post(name: clearChatNotification, object: nil)
                            chatCleared = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { chatCleared = false }
                        }) {
                            Text(chatCleared ? "Cleared ✓" : "Clear Chat")
                        }
                        .disabled(chatCleared)
                    }
                }

                Divider()

                Text("Error Code Reference").font(.headline)
                VStack(alignment: .leading, spacing: 4) {
                    Group {
                        codeRow("WX-001", "Invalid API URL (bug — report this)")
                        codeRow("WX-002", "Network timeout (>10 seconds)")
                        codeRow("WX-003", "HTTP error from weather provider")
                        codeRow("WX-004", "JSON decode failure (schema changed)")
                        codeRow("WX-005", "Empty response from weather API")
                    }
                    Group {
                        codeRow("LOC-001", "Location permission denied")
                        codeRow("LOC-002", "GPS acquisition timeout (>3s)")
                        codeRow("LOC-003", "Location services unavailable")
                        codeRow("LOC-004", "Reverse geocode failed")
                    }
                    Group {
                        codeRow("AI-001", "No AI provider key configured")
                        codeRow("AI-002", "All configured providers failed — no fallback")
                        codeRow("AI-003", "Provider rate limit exceeded")
                        codeRow("AI-004", "Key rejected by provider (401)")
                        codeRow("AI-005", "AI provider returned HTTP error")
                    }
                    Group {
                        codeRow("KEY-001", "Key invalid or expired (401/403)")
                        codeRow("KEY-002", "Key valid but rate-limited (429)")
                        codeRow("KEY-003", "Network error during key test")
                        codeRow("KEY-004", "Unexpected HTTP status during test")
                    }
                    Group {
                        codeRow("NOTIF-001", "Notification permission denied by user")
                        codeRow("NOTIF-002", "Failed to post error notification to system")
                    }
                }

                Spacer()
            }
            .padding(24)
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label); Spacer(); Text(value).foregroundColor(.secondary) }
    }

    private func codeRow(_ code: String, _ desc: String) -> some View {
        HStack(spacing: 10) {
            Text(code)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(.accentColor)
                .frame(width: 58, alignment: .leading)
            Text(desc).font(.system(size: 10)).foregroundColor(.secondary)
        }
    }

    private func weatherKitStatus() -> String {
        if #available(iOS 16.0, macOS 13.0, *) {
            return "Entitlement present · OS/API requirements met"
        } else {
            return "Entitlement present · Limited by OS/API availability"
        }
    }

    func clearWebKitCache() {
        let store = WKWebsiteDataStore.default()
        store.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                         modifiedSince: Date(timeIntervalSince1970: 0)) { }
    }
}

#if os(iOS)
// MARK: - Dynamic Island Debug
struct DynamicIslandDebugView: View {
    var body: some View {
        if #available(iOS 16.2, *) {
            DynamicIslandDebugContent()
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("DYNAMIC ISLAND")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(.accentColor)
                    compatRow("iOS Version", ProcessInfo.processInfo.operatingSystemVersionString)
                    compatRow("Live Activities API", "Unavailable — iOS 16.2+ required")
                    compatRow("Compatible Devices", "iPhone 14 Pro / Pro Max and later")
                }
                .padding(24)
            }
        }
    }

    private func compatRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).font(.system(size: 10)).foregroundColor(.secondary).frame(width: 140, alignment: .leading)
            Text(value).font(.system(size: 10, design: .monospaced)).foregroundColor(.primary).fixedSize(horizontal: false, vertical: true)
        }
    }
}

@available(iOS 16.2, *)
private struct DynamicIslandDebugContent: View {
    @ObservedObject private var lam = LiveActivityManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: Compatibility
                VStack(alignment: .leading, spacing: 8) {
                    Text("DYNAMIC ISLAND")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(.accentColor)

                    compatRow("iOS Version", ProcessInfo.processInfo.operatingSystemVersionString)
                    compatRow("Live Activities API", "Available (iOS 16.2+)")
                    compatRow("Activities Enabled",
                              ActivityAuthorizationInfo().areActivitiesEnabled ? "YES" : "NO (check Settings)")
                }
                .padding(14)
                .background(Color.settingsCardBackground)
                .cornerRadius(8)

                // MARK: Current State
                VStack(alignment: .leading, spacing: 8) {
                    Text("ACTIVITY STATE")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(.accentColor)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(lam.isActivityActive ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(lam.isActivityActive ? "ACTIVE" : "INACTIVE")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(lam.isActivityActive ? .green : .secondary)
                    }

                    if lam.isActivityActive {
                        infoRow("Title", lam.currentTitle.isEmpty ? "—" : lam.currentTitle)
                        infoRow("Body",  lam.currentBody.isEmpty  ? "—" : lam.currentBody)
                    }

                    if !lam.lastActivityStatus.isEmpty {
                        Text(lam.lastActivityStatus)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }

                    if let err = lam.lastActivityError {
                        Text(err)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.red)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                    }
                }
                .padding(14)
                .background(Color.settingsCardBackground)
                .cornerRadius(8)

                // MARK: Test Controls
                VStack(alignment: .leading, spacing: 12) {
                    Text("TEST CONTROLS")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(.accentColor)

                    testButton(label: "START WEATHER ALERT TEST", color: .orange, icon: "cloud.bolt.fill") {
                        lam.startWeatherAlert(
                            location: "Debug · Test City",
                            title: "SEVERE THUNDERSTORM",
                            body: "Large hail and damaging winds possible. Take shelter immediately.",
                            level: .warning
                        )
                    }

                    testButton(label: "START APP ERROR TEST", color: .red, icon: "xmark.circle.fill") {
                        lam.startAppError(
                            location: "Debug · Test City",
                            code: "WX-003",
                            description: "HTTP error from weather provider — tap to retry."
                        )
                    }

                    testButton(label: "END ACTIVITY", color: .gray, icon: "stop.circle") {
                        lam.endActivity()
                    }
                    .disabled(!lam.isActivityActive)
                    .opacity(lam.isActivityActive ? 1.0 : 0.4)

                    Text("To see the Live Activity: lock the device or swipe to home after pressing Start. The Simulator shows it as a lock-screen banner.")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(Color.settingsCardBackground)
                .cornerRadius(8)

                // MARK: Notes
                VStack(alignment: .leading, spacing: 6) {
                    Text("NOTES")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(.secondary)
                    Text("Dynamic Island Live Activities require a physical iPhone 14 Pro, 14 Pro Max, 15, 15 Pro, or later. The Simulator shows a lock-screen banner instead. Activities auto-expire after 1 hour if not ended.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(Color.settingsCardBackground)
                .cornerRadius(8)

                Spacer()
            }
            .padding(24)
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 48, alignment: .leading)
            Text(value)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func compatRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).font(.system(size: 10)).foregroundColor(.secondary).frame(width: 140, alignment: .leading)
            Text(value).font(.system(size: 10, design: .monospaced)).foregroundColor(.primary).fixedSize(horizontal: false, vertical: true)
        }
    }

    private func testButton(label: String, color: Color, icon: String,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 12))
                Text(label)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(1)
                Spacer()
            }
            .foregroundColor(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(color.opacity(0.1))
            .overlay(Rectangle().stroke(color.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

}
#endif

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View { SettingsView() }
}

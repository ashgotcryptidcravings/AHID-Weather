import SwiftUI
import AppKit
import WebKit

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            APIKeysSettingsView()
                .tabItem {
                    Label("API Keys", systemImage: "key")
                }

            WidgetSettingsView()
                .tabItem {
                    Label("Widgets", systemImage: "square.grid.2x2")
                }

            LocationSimulationView()
                .tabItem {
                    Label("Location", systemImage: "mappin.and.ellipse")
                }

            HealthInfoView()
                .tabItem {
                    Label("Health", systemImage: "heart.text.square")
                }

            DebugView()
                .tabItem {
                    Label("Debug", systemImage: "ladybug")
                }
        }
        .frame(width: 550, height: 480)
    }
}

// MARK: - General Settings
struct GeneralSettingsView: View {
    @AppStorage("useCelsius") private var useCelsius = false
    @State private var statusMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("General Settings")
                .font(.headline)

            // Temperature
            VStack(alignment: .leading, spacing: 8) {
                Text("TEMPERATURE")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .tracking(2)

                Toggle("Use Celsius", isOn: $useCelsius)
                    .toggleStyle(.switch)
            }

            Divider()

            Text("Theme colors and radar provider settings are configured in the app's built-in settings panel.")
                .font(.caption)
                .foregroundColor(.secondary)

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }

            Spacer()
        }
        .padding(24)
    }
}

// MARK: - API Keys Settings
struct APIKeysSettingsView: View {
    @AppStorage("apiKey_anthropic") private var anthropicKey = ""
    @AppStorage("apiKey_gemini") private var geminiKey = ""
    @AppStorage("apiKey_openai") private var openaiKey = ""
    @AppStorage("apiKey_owm") private var owmKey = ""
    @State private var statusMessage = ""
    @State private var showKeys = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("API Keys")
                    .font(.headline)

                Text("Keys are stored in UserDefaults. For production use, consider Keychain storage.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("Show Keys", isOn: $showKeys)
                    .toggleStyle(.switch)
                    .padding(.bottom, 4)

                Group {
                    apiKeySection(
                        name: "OPENWEATHERMAP",
                        badge: "MAP TILES",
                        description: "Unlocks map overlay layers — temperature, wind, clouds, pressure tiles.",
                        key: $owmKey,
                        placeholder: "your-owm-api-key"
                    )

                    apiKeySection(
                        name: "ANTHROPIC (CLAUDE)",
                        badge: "AI CHAT",
                        description: "Powers AI chat and forecast analysis via Claude. Primary AI provider.",
                        key: $anthropicKey,
                        placeholder: "sk-ant-..."
                    )

                    apiKeySection(
                        name: "GOOGLE GEMINI",
                        badge: "AI FALLBACK",
                        description: "Google's Gemini Flash — fast, generous free tier. Fallback AI provider.",
                        key: $geminiKey,
                        placeholder: "AIza..."
                    )

                    apiKeySection(
                        name: "OPENAI (GPT)",
                        badge: "AI FALLBACK",
                        description: "Alternative AI via GPT-4o-mini. Secondary fallback AI provider.",
                        key: $openaiKey,
                        placeholder: "sk-..."
                    )
                }

                HStack(spacing: 12) {
                    Button("Clear All Keys") {
                        anthropicKey = ""
                        geminiKey = ""
                        openaiKey = ""
                        owmKey = ""
                        statusMessage = "All keys cleared."
                    }
                    .foregroundColor(.red)

                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
    }

    private func apiKeySection(name: String, badge: String, description: String, key: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .tracking(1)

                Text(badge)
                    .font(.system(size: 8, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(key.wrappedValue.isEmpty ? Color.yellow.opacity(0.15) : Color.green.opacity(0.15))
                    .foregroundColor(key.wrappedValue.isEmpty ? .yellow : .green)
                    .clipShape(Capsule())
            }

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)

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
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
}

// MARK: - Widget Settings
struct WidgetSettingsView: View {
    @AppStorage("showConditions") private var showConditions = true
    @AppStorage("showAlerts") private var showAlerts = true
    @AppStorage("showMetrics") private var showMetrics = true
    @AppStorage("showHourly") private var showHourly = true
    @AppStorage("showRadar") private var showRadar = true
    @AppStorage("showAI") private var showAI = true

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Visible Sections")
                .font(.headline)

            Text("Toggle which sections are displayed in the main view.")
                .font(.caption)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                widgetToggle("Conditions", isOn: $showConditions)
                widgetToggle("Alerts", isOn: $showAlerts)
                widgetToggle("Data Metrics", isOn: $showMetrics)
                widgetToggle("24-Hour Forecast", isOn: $showHourly)
                widgetToggle("Radar & 7-Day", isOn: $showRadar)
                widgetToggle("AI Assistant", isOn: $showAI)
            }

            Spacer()
        }
        .padding(24)
    }

    private func widgetToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.callout)
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(6)
    }
}

// MARK: - Location Simulation
struct LocationSimulationView: View {
    @AppStorage("isSimulatingLocation") private var isSimulating = false
    @AppStorage("simulatedLat") private var simLat = "40.7128"
    @AppStorage("simulatedLon") private var simLon = "-74.0060"

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Location Simulation")
                .font(.headline)

            Toggle("Enable Manual Coordinates", isOn: $isSimulating)
                .toggleStyle(.switch)

            Text("Bypasses system GPS. Useful if your Mac's location services are restricted or if you want to view weather in another city.")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(spacing: 10) {
                HStack {
                    Text("Latitude")
                        .font(.callout)
                        .frame(width: 80, alignment: .leading)
                    TextField("e.g. 40.7128", text: $simLat)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text("Longitude")
                        .font(.callout)
                        .frame(width: 80, alignment: .leading)
                    TextField("e.g. -74.0060", text: $simLon)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .disabled(!isSimulating)
            .opacity(isSimulating ? 1.0 : 0.5)

            if isSimulating {
                Text("Changes will apply on next app launch.")
                    .font(.caption2)
                    .foregroundColor(.accentColor)
                    .padding(.top, 5)
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
                Text("How Weather Affects You")
                    .font(.headline)
                    .padding(.bottom, 16)

                healthItem(metric: "UV INDEX", text: "UV radiation damages DNA in skin cells. UV 3+ causes sunburn in 30min for fair skin. UV 8+ can burn in 10min. Cumulative exposure increases melanoma risk.")

                healthItem(metric: "AIR QUALITY (PM2.5)", text: "PM2.5 particles penetrate deep into lung tissue and enter the bloodstream. AQI 100+ triggers inflammation in airways. Long-term exposure above 50 correlates with cardiovascular disease.")

                healthItem(metric: "HUMIDITY", text: "Below 30% dries mucous membranes, increasing infection risk. Above 60% impairs sweat evaporation. Mold thrives above 70%, triggering allergies.")

                healthItem(metric: "HEAT INDEX", text: "Above 90°F: heat cramps possible. Above 105°F: heat exhaustion risk. Above 130°F: heat stroke territory. Hydration is your main defense.")

                healthItem(metric: "WIND CHILL", text: "At 0°F with 15mph wind, exposed skin gets frostbite in 30 minutes. Hypothermia begins when core temp drops below 95°F.")

                healthItem(metric: "BAROMETRIC PRESSURE", text: "Rapid drops (>6 hPa in 3hrs) trigger migraines in susceptible people. Low pressure expands joint fluid, increasing arthritis pain.")

                healthItem(metric: "DEW POINT", text: "Below 55°F feels comfortable. 55-65°F is noticeable. Above 65°F feels oppressive. Above 70°F is dangerous for prolonged exertion.")
            }
            .padding(24)
        }
    }

    private func healthItem(metric: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(metric)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(2)
                .foregroundColor(.accentColor)

            Text(text)
                .font(.callout)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

// MARK: - Debug
struct DebugView: View {
    @State private var cacheCleared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Device & Session Info")
                .font(.headline)

            VStack(spacing: 8) {
                HStack {
                    Text("macOS Version")
                    Spacer()
                    Text(ProcessInfo.processInfo.operatingSystemVersionString)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("App Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundColor(.secondary)
                }
            }
            .font(.callout)

            Divider()

            Text("Cache Controls")
                .font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text("Clear Weather Cache")
                        .font(.subheadline)
                    Text("Forces fresh data on next fetch.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: {
                    clearWebKitCache()
                }) {
                    Text(cacheCleared ? "Cleared!" : "Clear Cache")
                }
                .disabled(cacheCleared)
            }

            Spacer()
        }
        .padding(24)
    }

    func clearWebKitCache() {
        let dataStore = WKWebsiteDataStore.default()
        let websiteDataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let dateFrom = Date(timeIntervalSince1970: 0)
        dataStore.removeData(ofTypes: websiteDataTypes, modifiedSince: dateFrom) {
            DispatchQueue.main.async {
                self.cacheCleared = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.cacheCleared = false
                }
            }
        }
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

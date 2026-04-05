import SwiftUI
import AppKit
import WebKit

struct SettingsView: View {
    var body: some View {
        TabView {
            // Tab 1
            PermissionsView()
                .tabItem {
                    Label("Permissions", systemImage: "lock.shield")
                }
            
            // Tab 2: NEW Location Simulation Tab
            LocationSimulationView()
                .tabItem {
                    Label("Location", systemImage: "mappin.and.ellipse")
                }
            
            // Tab 3
            DebugView()
                .tabItem {
                    Label("Debug", systemImage: "ladybug")
                }
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - Permissions Tab
struct PermissionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("System Permissions")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Location Access")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Required to automatically fetch weather for your current area.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Open System Settings") {
                    openLocationSettings()
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Network Access")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Required to communicate with APIs. Granted via App Sandbox.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("Active")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(6)
            }
            Spacer()
        }
        .padding(24)
    }
    
    func openLocationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Location Simulation Tab
struct LocationSimulationView: View {
    // Uses AppStorage to persist these values in the app's settings
    @AppStorage("isSimulatingLocation") private var isSimulating = false
    @AppStorage("simulatedLat") private var simLat = "40.7128" // Default: NYC
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
                Text("Changes will apply on app restart or manual refresh (R).")
                    .font(.caption2)
                    .foregroundColor(.accentColor)
                    .padding(.top, 5)
            }
            
            Spacer()
        }
        .padding(24)
    }
}

// MARK: - Debug Tab
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
                    Text(ProcessInfo.processInfo.operatingSystemVersionString).foregroundColor(.secondary)
                }
                HStack {
                    Text("App Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0").foregroundColor(.secondary)
                }
            }
            .font(.callout)
            
            Divider().padding(.vertical, 4)
            
            Text("Native Web Container Tools")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Cache Controller")
                        .font(.subheadline)
                    Text("Hard reset of all HTML storage/keys.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: {
                    clearWebKitCache()
                }) {
                    Text(cacheCleared ? "Cleared!" : "Wipe WebKit Cache")
                }
                .disabled(cacheCleared)
            }
            
            Divider().padding(.vertical, 4)
            
            Text("Advanced Debugging")
                .font(.headline)
            Text("Right-click inside the main app window and select Inspect Element to access the full Network/API Inspector.")
                .font(.caption)
                .foregroundColor(.secondary)
            
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

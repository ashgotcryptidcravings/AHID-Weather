import SwiftUI

@main
struct AHIDWeatherApp: App {
    var body: some Scene {
        #if os(iOS)
        WindowGroup {
            ContentView()
                .background(Color(red: 0.03, green: 0.03, blue: 0.03))
        }
        #else
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 700)
                .background(Color(red: 0.03, green: 0.03, blue: 0.03))
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }

            CommandMenu("Weather") {
                Button("Refresh Data") {
                    NotificationCenter.default.post(name: .refreshWeather, object: nil)
                }
                .keyboardShortcut("r")
            }
        }

        Settings {
            SettingsView()
        }
        #endif
    }
}

extension Notification.Name {
    static let refreshWeather = Notification.Name("refreshWeather")
}

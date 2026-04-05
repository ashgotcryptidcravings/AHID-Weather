import SwiftUI

@main
struct AHIDWeatherApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
                .background(Color(red: 0.03, green: 0.03, blue: 0.03))
        } 
        // This creates the "Settings..." menu item automatically
        Settings {
            SettingsView()
        }
    }
}

import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // 1. Read the simulation settings from UserDefaults
        let isSimulating = UserDefaults.standard.bool(forKey: "isSimulatingLocation")
        let lat = UserDefaults.standard.string(forKey: "simulatedLat") ?? "40.7128"
        let lon = UserDefaults.standard.string(forKey: "simulatedLon") ?? "-74.0060"
        
        // 2. If simulation is ON, inject a script that sets LAT/LON and skips acquireLocation()
        if isSimulating {
            let source = """
                window.NATIVE_SIMULATED_LAT = \(lat);
                window.NATIVE_SIMULATED_LON = \(lon);
                window.IS_SIMULATING = true;
            """
            let script = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
            configuration.userContentController.addUserScript(script)
        }
        
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        let webView = WKWebView(frame: .zero, configuration: configuration)
        
        if let htmlPath = Bundle.main.path(forResource: "index", ofType: "html") {
            let htmlUrl = URL(fileURLWithPath: htmlPath)
            let directoryUrl = htmlUrl.deletingLastPathComponent()
            webView.loadFileURL(htmlUrl, allowingReadAccessTo: directoryUrl)
        }
        
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}

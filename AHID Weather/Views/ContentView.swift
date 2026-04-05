import SwiftUI

struct ContentView: View {
    var body: some View {
        WebView()
            // Ignores the safe area so your weather app stretches edge-to-edge
            .edgesIgnoringSafeArea(.all)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

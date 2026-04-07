#if os(iOS)
import WidgetKit
import SwiftUI

struct AHIDWeatherWidgetBundle: WidgetBundle {
    var body: some Widget {
        AHIDLiveActivityWidget()
    }
}
#endif

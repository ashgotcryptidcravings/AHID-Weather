#if os(iOS)
import ActivityKit
import SwiftUI

// MARK: - Shared Live Activity Attributes
// This file is compiled into BOTH the main app target and the Widget Extension target.
// ActivityKit matches activities by type name — both targets must define identical types.

public struct AHIDActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var title: String        // "TORNADO WARNING" or "LOC-001"
        public var body: String         // Brief detail line
        public var level: Level
        public var icon: String         // SF Symbol name
        public var updatedAt: Date

        public enum Level: String, Codable, Hashable {
            case info, warning, danger, appError

            public var color: Color {
                switch self {
                case .info:     return Color(red: 0.659, green: 0.333, blue: 0.969)
                case .warning:  return .yellow
                case .danger:   return Color(red: 1.0, green: 0.2, blue: 0.2)
                case .appError: return .orange
                }
            }

            public var sfSymbol: String {
                switch self {
                case .info:     return "info.circle.fill"
                case .warning:  return "exclamationmark.triangle.fill"
                case .danger:   return "exclamationmark.octagon.fill"
                case .appError: return "xmark.circle.fill"
                }
            }
        }
    }

    public var locationName: String   // Static — city name e.g. "TOLEDO"

    public init(locationName: String) {
        self.locationName = locationName
    }
}
#endif

#if os(iOS)
import ActivityKit
import Foundation

// MARK: - Live Activity Manager
// Manages Dynamic Island Live Activities for weather alerts and app errors.
// Requires iOS 16.2+; all public entry points are guarded accordingly.

@available(iOS 16.2, *)
@MainActor
final class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()

    @Published var isActivityActive: Bool = false
    @Published var currentTitle: String = ""
    @Published var currentBody: String = ""
    @Published var lastActivityStatus: String = ""
    @Published var lastActivityError: String? = nil

    private var currentActivity: Activity<AHIDActivityAttributes>?

    private init() {
        guard #available(iOS 16.2, *) else { return }
        currentActivity = Activity<AHIDActivityAttributes>.activities.first
        isActivityActive = currentActivity != nil
        if let a = currentActivity {
            currentTitle = a.content.state.title
            currentBody  = a.content.state.body
        }
    }

    // MARK: - Start

    func startWeatherAlert(location: String, title: String, body: String,
                           level: AHIDActivityAttributes.ContentState.Level) {
        guard #available(iOS 16.2, *) else { return }
        Task {
            await _start(location: location, title: title, body: body, level: level,
                         icon: level.sfSymbol)
        }
    }

    func startAppError(location: String, code: String, description: String) {
        guard #available(iOS 16.2, *) else { return }
        Task {
            await _start(location: location, title: code, body: description,
                         level: .appError, icon: "xmark.circle.fill")
        }
    }

    // MARK: - Update

    func update(title: String, body: String,
                level: AHIDActivityAttributes.ContentState.Level) {
        guard #available(iOS 16.2, *), let activity = currentActivity else { return }
        let state = AHIDActivityAttributes.ContentState(
            title: title, body: body, level: level,
            icon: level.sfSymbol, updatedAt: Date()
        )
        Task {
            await activity.update(ActivityContent(
                state: state,
                staleDate: Date().addingTimeInterval(3600)
            ))
        }
        currentTitle = title
        currentBody  = body
    }

    // MARK: - End

    func endActivity() {
        guard #available(iOS 16.2, *) else { return }
        Task {
            await endAllActivities()
        }
    }

    @available(iOS 16.2, *)
    private func endAllActivities() async {
        for activity in Activity<AHIDActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        currentActivity  = nil
        isActivityActive = false
        currentTitle     = ""
        currentBody      = ""
        lastActivityStatus = "[\(timestamp())] Activity ended"
    }

    // MARK: - Private

    @available(iOS 16.2, *)
    private func _start(location: String, title: String, body: String,
                        level: AHIDActivityAttributes.ContentState.Level, icon: String) async {
        lastActivityError = nil

        // Await full teardown of any existing activity before starting new one
        await endAllActivities()

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            lastActivityError = "Live Activities are disabled. Go to Settings → \(Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "App") → Live Activities and enable them."
            lastActivityStatus = "[\(timestamp())] FAILED — activities disabled"
            return
        }

        let attrs = AHIDActivityAttributes(locationName: location)
        let state = AHIDActivityAttributes.ContentState(
            title: title, body: body, level: level,
            icon: icon, updatedAt: Date()
        )
        do {
            let activity = try Activity.request(
                attributes: attrs,
                content: ActivityContent(
                    state: state,
                    staleDate: Date().addingTimeInterval(3600)
                ),
                pushType: nil
            )
            currentActivity    = activity
            isActivityActive   = true
            currentTitle       = title
            currentBody        = body
            lastActivityStatus = "[\(timestamp())] Activity started — ID: \(activity.id)"
            print("[AHID DI] Live Activity started: \(activity.id)")
        } catch {
            lastActivityError  = error.localizedDescription
            lastActivityStatus = "[\(timestamp())] FAILED: \(error.localizedDescription)"
            print("[AHID DI] Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    private func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: Date())
    }
}
#endif

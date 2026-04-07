import Foundation
import UserNotifications
#if os(iOS)
import AudioToolbox
#elseif os(macOS)
import AppKit
#endif

// MARK: - Error Notification Service
// Handles in-app sound feedback and local push notifications when an AppError is thrown.

@MainActor
final class ErrorNotificationService {
    static let shared = ErrorNotificationService()
    private init() {}

    // MARK: - Permission
    /// Request notification authorization. Call once at app start.
    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            if !granted {
                print("[AHID] NOTIF-001: Notification permission denied by user.")
            }
        } catch {
            print("[AHID] NOTIF-001: Permission request failed — \(error.localizedDescription)")
        }
    }

    // MARK: - Error Dispatch
    /// Call whenever an AppError is caught. Respects the user's sound/notification preferences.
    func handle(_ error: AppError, soundEnabled: Bool, notifEnabled: Bool) {
        if soundEnabled { playErrorSound() }
        if notifEnabled { scheduleNotification(for: error) }
    }

    // MARK: - Sound
    private func playErrorSound() {
        #if os(macOS)
        NSSound.beep()
        #elseif os(iOS)
        // Sound ID 1322 is a standard alert chime present across iOS versions.
        AudioServicesPlayAlertSound(SystemSoundID(1322))
        #endif
    }

    // MARK: - Notification
    private func scheduleNotification(for error: AppError) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized ||
                  settings.authorizationStatus == .provisional else {
                print("[AHID] NOTIF-001: Notifications not authorized — skipping.")
                return
            }

            let content        = UNMutableNotificationContent()
            content.title      = "AHID Weather · \(error.code)"
            content.body       = error.localizedDescription 
            content.sound      = .default

            // Re-use the same identifier per error code so rapid retries don't stack.
            let request = UNNotificationRequest(
                identifier: "ahid.error.\(error.code)",
                content:    content,
                trigger:    nil          // deliver immediately
            )

            UNUserNotificationCenter.current().add(request) { err in
                if let err = err {
                    print("[AHID] NOTIF-002: Failed to post notification — \(err.localizedDescription)")
                }
            }
        }
    }
}

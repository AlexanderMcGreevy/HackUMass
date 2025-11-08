//
//  NotificationHelper.swift
//  VaultEye
//
//  Local notification handling
//

import UserNotifications
import UIKit

final class NotificationHelper: NSObject {
    static let shared = NotificationHelper()

    private override init() {
        super.init()
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - Send Notifications

    func sendCompletionNotification(matchedCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Scan Complete"
        content.body = "Found \(matchedCount) matching images"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "scan-complete",
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }

    func sendProgressNotification(processed: Int, total: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Scanning Photos"
        content.body = "Processed \(processed) of \(total) images"
        content.sound = nil

        let request = UNNotificationRequest(
            identifier: "scan-progress",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send progress notification: \(error)")
            }
        }
    }

    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationHelper: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification banner even when app is in foreground
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap
        completionHandler()
    }
}

//
//  BGTasks.swift
//  VaultEye
//
//  Background task scheduling and registration
//

import BackgroundTasks
import Foundation

final class BGTasks {
    static let taskIdentifier = "com.vaulteye.scan"

    // MARK: - Registration

    static func register(scanManager: BackgroundScanManager) {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { task in
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }

            handleBackgroundScan(task: processingTask, scanManager: scanManager)
        }

        print("✅ Registered background task: \(taskIdentifier)")
    }

    // MARK: - Scheduling

    static func scheduleProcessing() {
        let request = BGProcessingTaskRequest(identifier: taskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30) // Try in 30 seconds

        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Scheduled background processing task")
        } catch {
            print("❌ Failed to schedule background task: \(error)")
        }
    }

    static func cancelAllTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
        print("🚫 Cancelled background tasks")
    }

    // MARK: - Background Task Handler

    private static func handleBackgroundScan(
        task: BGProcessingTask,
        scanManager: BackgroundScanManager
    ) {
        print("🔄 Background task started")

        // Handle expiration
        var isExpired = false
        task.expirationHandler = {
            print("⏰ Background task expiring - checkpointing")
            isExpired = true

            Task { @MainActor in
                scanManager.checkpoint()
            }

            // Reschedule for later
            scheduleProcessing()
        }

        // Run the scan
        Task { @MainActor in
            let success = await scanManager.resumeOrStartIfNeeded(threshold: 85)

            if !isExpired {
                task.setTaskCompleted(success: success)
                print("✅ Background task completed: \(success)")
            }
        }
    }
}

// MARK: - Info.plist Requirements
/*
 Add these keys to your Info.plist:

 <key>BGTaskSchedulerPermittedIdentifiers</key>
 <array>
     <string>com.vaulteye.scan</string>
 </array>

 <key>UIBackgroundModes</key>
 <array>
     <string>processing</string>
 </array>

 <key>NSPhotoLibraryUsageDescription</key>
 <string>VaultEye needs access to your photos to scan for sensitive information</string>

 <key>NSUserNotificationsUsageDescription</key>
 <string>VaultEye sends notifications when background scans complete</string>
 */

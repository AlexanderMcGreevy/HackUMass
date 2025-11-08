//
//  VaultEyeApp.swift
//  VaultEye
//
//  Created by Alexander McGreevy on 11/7/25.
//

import SwiftUI
import UserNotifications

@main
struct VaultEyeApp: App {
    @StateObject private var scanManager = BackgroundScanManager()

    init() {
        // Register background tasks
        BGTasks.register(scanManager: BackgroundScanManager())

        // Set notification delegate
        UNUserNotificationCenter.current().delegate = NotificationHelper.shared
    }
    @StateObject private var activityTracker = ActivityTracker()

    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Photos", systemImage: "photo.stack")
                    }

                ScanScreen()
                    .environmentObject(scanManager)
                    .tabItem {
                        Label("Background Scan", systemImage: "magnifyingglass")
                    }

                SelectedImagesView()
                    .environmentObject(scanManager)
                    .tabItem {
                        Label("Matched", systemImage: "checkmark.circle")
                    }
                    .environmentObject(activityTracker)
                    .tabItem {
                        Label("Scan", systemImage: "magnifyingglass")
                    }

                NavigationStack {
                    DashboardView(activityTracker: activityTracker)
                }
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
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

 <key>NSPhotoLibraryAddUsageDescription</key>
 <string>VaultEye needs to save redacted images to your photo library</string>

 <key>NSUserNotificationsUsageDescription</key>
 <string>VaultEye sends notifications when background scans complete</string>
 */

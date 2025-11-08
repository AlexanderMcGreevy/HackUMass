//
//  StatisticsManager.swift
//  VaultEye
//
//  Tracks app-wide statistics for photos processed, deleted, redacted, etc.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class StatisticsManager: ObservableObject {

    // MARK: - Published Statistics

    @Published var photosScanned: Int = 0
    @Published var photosDeleted: Int = 0
    @Published var photosKept: Int = 0
    @Published var photosRedacted: Int = 0
    @Published var totalScans: Int = 0
    @Published var lastScanDate: Date?

    // MARK: - Computed Stats

    var totalProcessed: Int {
        photosDeleted + photosKept
    }

    var deletionRate: Double {
        guard totalProcessed > 0 else { return 0 }
        return Double(photosDeleted) / Double(totalProcessed)
    }

    var keepRate: Double {
        guard totalProcessed > 0 else { return 0 }
        return Double(photosKept) / Double(totalProcessed)
    }

    // MARK: - Persistence

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let photosScanned = "stats_photos_scanned"
        static let photosDeleted = "stats_photos_deleted"
        static let photosKept = "stats_photos_kept"
        static let photosRedacted = "stats_photos_redacted"
        static let totalScans = "stats_total_scans"
        static let lastScanDate = "stats_last_scan_date"
    }

    // MARK: - Initialization

    init() {
        loadStats()
    }

    // MARK: - Update Methods

    func recordScanStarted() {
        totalScans += 1
        lastScanDate = Date()
        saveStats()
    }

    func recordPhotosScanned(_ count: Int) {
        photosScanned += count
        saveStats()
    }

    func recordPhotoDeleted() {
        photosDeleted += 1
        saveStats()
    }

    func recordPhotosDeleted(_ count: Int) {
        photosDeleted += count
        saveStats()
    }

    func recordPhotoKept() {
        photosKept += 1
        saveStats()
    }

    func recordPhotosKept(_ count: Int) {
        photosKept += count
        saveStats()
    }

    func recordPhotoRedacted() {
        photosRedacted += 1
        saveStats()
    }

    // MARK: - Reset

    func resetStats() {
        photosScanned = 0
        photosDeleted = 0
        photosKept = 0
        photosRedacted = 0
        totalScans = 0
        lastScanDate = nil
        saveStats()
    }

    // MARK: - Persistence Helpers

    private func loadStats() {
        photosScanned = defaults.integer(forKey: Keys.photosScanned)
        photosDeleted = defaults.integer(forKey: Keys.photosDeleted)
        photosKept = defaults.integer(forKey: Keys.photosKept)
        photosRedacted = defaults.integer(forKey: Keys.photosRedacted)
        totalScans = defaults.integer(forKey: Keys.totalScans)

        if let timestamp = defaults.object(forKey: Keys.lastScanDate) as? TimeInterval {
            lastScanDate = Date(timeIntervalSince1970: timestamp)
        }
    }

    private func saveStats() {
        defaults.set(photosScanned, forKey: Keys.photosScanned)
        defaults.set(photosDeleted, forKey: Keys.photosDeleted)
        defaults.set(photosKept, forKey: Keys.photosKept)
        defaults.set(photosRedacted, forKey: Keys.photosRedacted)
        defaults.set(totalScans, forKey: Keys.totalScans)

        if let lastScanDate = lastScanDate {
            defaults.set(lastScanDate.timeIntervalSince1970, forKey: Keys.lastScanDate)
        }
    }
}

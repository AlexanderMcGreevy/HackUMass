//
//  BackgroundScanManager.swift
//  VaultEye
//
//  Manages background photo scanning with Core ML classification
//

import Foundation
import Photos
import SwiftUI
import Combine

@MainActor
final class BackgroundScanManager: ObservableObject {

    // MARK: - Published State

    @Published var total: Int = 0
    @Published var processed: Int = 0
    @Published var isRunning: Bool = false
    @Published var lastCompletionSummary: String?

    // MARK: - Private State

    private let store = ResultStore()
    private var isCancelled = false
    private var classifier: ImageClassifier?
    private var currentTask: Task<Void, Never>?
    private weak var statsManager: StatisticsManager?

    private let batchSize = 20 // Checkpoint every N images
    private let maxImageSize = CGSize(width: 1024, height: 1024)

    // MARK: - Configuration

    func configure(statsManager: StatisticsManager) {
        self.statsManager = statsManager
    }

    // MARK: - Initialization

    init() {
        // Try to load existing state
        let state = store.loadOrCreate(threshold: 85)
        if !state.completed && !state.assetIDs.isEmpty {
            self.total = state.assetIDs.count
            self.processed = state.cursorIndex
        }

        if state.completed && !state.selectedIDs.isEmpty {
            self.lastCompletionSummary = "\(state.selectedIDs.count) images matched ≥ \(state.threshold)"
        }
    }

    // MARK: - Public API

    /// Start a new scan from the beginning
    func startScan(threshold: Int) async {
        guard !isRunning else {
            print("⚠️ Scan already running")
            return
        }

        // Request permissions
        let photosGranted = await PhotoAccess.requestAccess()
        guard photosGranted else {
            print("❌ Photos permission denied")
            return
        }

        let notificationsGranted = await NotificationHelper.shared.requestPermission()
        if !notificationsGranted {
            print("⚠️ Notifications permission denied")
        }

        // Reset state
        store.reset()
        isCancelled = false

        // Fetch all image assets
        print("📸 Fetching all image assets...")
        let assetIDs = PhotoAccess.fetchAllImageAssets()

        guard !assetIDs.isEmpty else {
            print("⚠️ No images found")
            return
        }

        // Initialize state
        var state = ScanState()
        state.assetIDs = assetIDs
        state.threshold = threshold
        state.cursorIndex = 0
        state.selectedIDs = []
        state.completed = false
        store.save(state)

        self.total = assetIDs.count
        self.processed = 0
        self.isRunning = true

        // Record scan started
        statsManager?.recordScanStarted()

        print("🚀 Starting scan: \(total) images, threshold: \(threshold)")

        // Schedule background task as fallback
        BGTasks.scheduleProcessing()

        // Start processing
        processScan(state: state)
    }

    /// Resume or start a scan (used by background task)
    func resumeOrStartIfNeeded(threshold: Int) async -> Bool {
        guard !isRunning else {
            print("⚠️ Scan already running")
            return true
        }

        // Check permissions
        guard PhotoAccess.isAuthorized() else {
            print("❌ Photos permission not granted")
            return false
        }

        // Load state
        var state = store.loadOrCreate(threshold: threshold)

        // If already completed, nothing to do
        if state.completed {
            print("✅ Scan already completed")
            return true
        }

        // If no assets, fetch them
        if state.assetIDs.isEmpty {
            let assetIDs = PhotoAccess.fetchAllImageAssets()
            guard !assetIDs.isEmpty else {
                print("⚠️ No images found")
                return false
            }
            state.assetIDs = assetIDs
            state.threshold = threshold
            store.save(state)
        }

        self.total = state.assetIDs.count
        self.processed = state.cursorIndex
        self.isRunning = true

        print("🔄 Resuming scan from \(processed)/\(total)")

        // Process from cursor
        processScan(state: state)

        return true
    }

    /// Cancel the current scan
    func cancel() {
        print("🛑 Cancelling scan")
        isCancelled = true
        currentTask?.cancel()
        isRunning = false

        BGTasks.cancelAllTasks()
    }

    /// Checkpoint current progress
    func checkpoint() {
        var state = store.loadOrCreate(threshold: 85)
        state.cursorIndex = processed
        store.save(state)
        print("💾 Checkpointed at \(processed)/\(total)")
    }

    // MARK: - Private Processing

    private func processScan(state: ScanState) {
        Task {
            await processScanAsync(state: state)
        }
    }

    private func processScanAsync(state: ScanState) async {
        var currentState = state

        // Initialize classifier
        if classifier == nil {
            do {
                classifier = try ImageClassifier()
            } catch {
                print("⚠️ Failed to load Core ML model, using mock classifier")
                classifier = ImageClassifier.mock()
            }
        }

        guard let classifier = classifier else {
            print("❌ No classifier available")
            isRunning = false
            return
        }

        // Process assets from cursor
        let startIndex = currentState.cursorIndex
        let endIndex = currentState.assetIDs.count

        for index in startIndex..<endIndex {
            // Check cancellation
            if isCancelled || Task.isCancelled {
                print("🛑 Scan cancelled at \(index)/\(total)")
                checkpoint()
                isRunning = false
                return
            }

            let assetID = currentState.assetIDs[index]

            // Process this asset
            let didMatch = await processAsset(
                assetID: assetID,
                threshold: currentState.threshold,
                classifier: classifier
            )

            if didMatch {
                currentState.selectedIDs.insert(assetID)
            }

            // Update progress
            currentState.cursorIndex = index + 1
            self.processed = currentState.cursorIndex

            // Checkpoint every N images
            if (index + 1) % batchSize == 0 {
                store.save(currentState)
                print("💾 Checkpoint: \(processed)/\(total)")
            }
        }

        // Scan complete
        currentState.completed = true
        store.save(currentState)

        self.isRunning = false
        self.lastCompletionSummary = "\(currentState.selectedIDs.count) images matched ≥ \(currentState.threshold)"

        // Record stats
        statsManager?.recordPhotosScanned(currentState.assetIDs.count)

        print("🎉 Scan complete: \(currentState.selectedIDs.count) matches")

        // Send notification
        NotificationHelper.shared.sendCompletionNotification(matchedCount: currentState.selectedIDs.count)
    }

    private func processAsset(
        assetID: String,
        threshold: Int,
        classifier: ImageClassifier
    ) async -> Bool {
        guard let asset = PhotoAccess.fetchAsset(byLocalIdentifier: assetID) else {
            print("⚠️ Asset not found: \(assetID)")
            return false
        }

        do {
            // Load image with downscaling
            guard let cgImage = try await PhotoAccess.requestCGImage(
                for: asset,
                targetSize: maxImageSize
            ) else {
                print("⚠️ Failed to load image: \(assetID)")
                return false
            }

            // Classify (mock mode will return 100 for all photos)
            let confidence = try await classifier.confidence(for: cgImage)

            let matched = confidence >= threshold

            if matched {
                print("✅ Match: \(assetID) (confidence: \(confidence))")
            }

            return matched
        } catch {
            print("❌ Error processing \(assetID): \(error)")
            return false
        }
    }

    // MARK: - State Access

    func getSelectedAssetIDs() -> [String] {
        let state = store.loadOrCreate(threshold: 85)
        return Array(state.selectedIDs)
    }

    func isCompleted() -> Bool {
        let state = store.loadOrCreate(threshold: 85)
        return state.completed
    }
}

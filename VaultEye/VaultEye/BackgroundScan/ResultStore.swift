//
//  ResultStore.swift
//  VaultEye
//
//  Background scan state persistence
//

import Foundation

struct ScanState: Codable {
    var assetIDs: [String]            // all image asset localIdentifiers to process
    var cursorIndex: Int              // next index to process
    var selectedIDs: Set<String>      // those that passed threshold
    var threshold: Int
    var completed: Bool

    init() {
        self.assetIDs = []
        self.cursorIndex = 0
        self.selectedIDs = []
        self.threshold = 85
        self.completed = false
    }
}

final class ResultStore {
    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        self.fileURL = appSupport.appendingPathComponent("ScanState.json")
    }

    func loadOrCreate(threshold: Int) -> ScanState {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            var state = ScanState()
            state.threshold = threshold
            return state
        }

        do {
            let data = try Data(contentsOf: fileURL)
            var state = try JSONDecoder().decode(ScanState.self, from: data)

            // If threshold changed, reset the scan
            if state.threshold != threshold {
                state.threshold = threshold
                state.cursorIndex = 0
                state.selectedIDs = []
                state.completed = false
            }

            return state
        } catch {
            print("Failed to load scan state: \(error)")
            var state = ScanState()
            state.threshold = threshold
            return state
        }
    }

    func save(_ state: ScanState) {
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save scan state: \(error)")
        }
    }

    func reset() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}

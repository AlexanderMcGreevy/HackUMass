//
//  ScanScreen.swift
//  VaultEye
//
//  Background scan control screen with progress
//

import SwiftUI

struct ScanScreen: View {
    @EnvironmentObject var scanManager: BackgroundScanManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var threshold: Int = 85

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Status Section
                statusSection

                Spacer()

                // Progress Section
                if scanManager.isRunning {
                    progressSection
                }

                Spacer()

                // Controls Section
                controlsSection

                // Last completion summary
                if let summary = scanManager.lastCompletionSummary {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding()
            .navigationTitle("Background Scan")
            .onChange(of: scenePhase) { oldPhase, newPhase in
                handleScenePhaseChange(from: oldPhase, to: newPhase)
            }
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: 12) {
            Image(systemName: scanManager.isRunning ? "hourglass" : "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(scanManager.isRunning ? .blue : .green)

            Text(scanManager.isRunning ? "Scanning..." : "Ready")
                .font(.title2)
                .fontWeight(.semibold)

            if scanManager.isRunning {
                Text("Processing photos in background")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Tap Start to scan your photo library")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: 16) {
            ProgressView(
                value: Double(scanManager.processed),
                total: Double(scanManager.total)
            )
            .progressViewStyle(.linear)

            HStack {
                Text("\(scanManager.processed) / \(scanManager.total)")
                    .font(.headline)

                Spacer()

                Text("\(progressPercentage)%")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var progressPercentage: Int {
        guard scanManager.total > 0 else { return 0 }
        return Int((Double(scanManager.processed) / Double(scanManager.total)) * 100)
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        VStack(spacing: 12) {
            // Threshold Picker
            if !scanManager.isRunning {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confidence Threshold: \(threshold)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Slider(value: Binding(
                        get: { Double(threshold) },
                        set: { threshold = Int($0) }
                    ), in: 0...100, step: 5)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Start/Cancel Button
            if scanManager.isRunning {
                Button(action: {
                    scanManager.cancel()
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Cancel Scan")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Button(action: {
                    Task {
                        await scanManager.startScan(threshold: threshold)
                    }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Scan")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            // Settings Link
            Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                HStack {
                    Image(systemName: "gear")
                    Text("Open Settings")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
        }
    }

    // MARK: - Scene Phase Handling

    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            if scanManager.isRunning {
                print("📱 App entering background - scheduling BG task")
                BGTasks.scheduleProcessing()
            }
        case .active:
            print("📱 App became active")
        case .inactive:
            print("📱 App became inactive")
        @unknown default:
            break
        }
    }
}

// MARK: - Preview

#Preview {
    ScanScreen()
        .environmentObject(BackgroundScanManager())
}

//
//  SwipeCardView.swift
//  VaultEye
//
//  Created by Alexander McGreevy on 11/8/25.
//

import SwiftUI
internal import Photos

// Constants
private let swipeThreshold: CGFloat = 140
private let maxCardHeight: CGFloat = 480

struct SwipeCardView<Content: View>: View {
    let content: Content
    let onDelete: () -> Void
    let onKeep: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    @State private var hasTriggeredHaptic = false

    private var progress: CGFloat {
        min(1, abs(offset) / swipeThreshold)
    }

    private var isOverThreshold: Bool {
        abs(offset) > swipeThreshold
    }

    init(
        @ViewBuilder content: () -> Content,
        onDelete: @escaping () -> Void,
        onKeep: @escaping () -> Void
    ) {
        self.content = content()
        self.onDelete = onDelete
        self.onKeep = onKeep
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Background glows - tall half capsules extending to bottom
                // Left edge - green (keep)
                if offset < 0 {
                    LinearGradient(
                        colors: [
                            Color.green.opacity(progress * 0.7),
                            Color.green.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 150)
                    .mask(
                        Capsule()
                            .frame(width: 300, height: geometry.size.height)
                            .offset(x: -150) // Shift left so only right half is visible
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .allowsHitTesting(false)
                }

                // Right edge - red (delete)
                if offset > 0 {
                    LinearGradient(
                        colors: [
                            Color.red.opacity(0),
                            Color.red.opacity(progress * 0.7)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 150)
                    .mask(
                        Capsule()
                            .frame(width: 300, height: geometry.size.height)
                            .offset(x: 150) // Shift right so only left half is visible
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .allowsHitTesting(false)
                }

                // Card content - follows drag continuously with NO animation on offset
                content
                    .frame(maxHeight: maxCardHeight)
                    .background(Color(.systemBackground))
                    .cornerRadius(24)
                    .shadow(
                        color: Color.black.opacity(isDragging ? 0.2 : 0.1),
                        radius: isDragging ? 20 : 10,
                        x: 0,
                        y: isDragging ? 10 : 5
                    )
                    .offset(x: offset)  // Direct offset - no animation
                    .rotationEffect(.degrees(Double(offset) / 20))
                    .scaleEffect(isDragging ? 1.02 : 1.0)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                isDragging = true
                                // Card follows finger exactly - no animation
                                offset = value.translation.width

                                // Haptic feedback when crossing threshold
                                if isOverThreshold && !hasTriggeredHaptic {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    hasTriggeredHaptic = true
                                } else if !isOverThreshold && hasTriggeredHaptic {
                                    hasTriggeredHaptic = false
                                }
                            }
                            .onEnded { _ in
                                isDragging = false

                                if offset > swipeThreshold {
                                    // Swipe right → Delete (only on release)
                                    dismissCard(direction: 1) {
                                        onDelete()
                                    }
                                } else if offset < -swipeThreshold {
                                    // Swipe left → Keep (only on release)
                                    dismissCard(direction: -1) {
                                        onKeep()
                                    }
                                } else {
                                    // Snap back to center
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        offset = 0
                                        hasTriggeredHaptic = false
                                    }
                                }
                            }
                    )
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private func dismissCard(direction: CGFloat, completion: @escaping () -> Void) {
        // Use a large enough offset to dismiss off-screen
        let dismissOffset: CGFloat = direction * 500

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            offset = dismissOffset
        }

        // Small haptic on dismiss
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Call completion after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            completion()
        }
    }
}

// Specialized version for DetectionResult with redaction support
struct DetectionResultCard: View {
    let result: DetectionResult
    let photoLibraryManager: PhotoLibraryManager
    let deleteBatchManager: DeleteBatchManager
    let redactionService: RedactionServiceProtocol

    @State private var fullSizeImage: UIImage?
    @State private var dragOffset: CGFloat = 0
    @State private var isRedacting = false
    @State private var redactionError: String?
    @State private var showError = false

    private let redactionSwipeThreshold: CGFloat = 120

    init(
        result: DetectionResult,
        photoLibraryManager: PhotoLibraryManager,
        deleteBatchManager: DeleteBatchManager,
        redactionService: RedactionServiceProtocol = RedactionService()
    ) {
        self.result = result
        self.photoLibraryManager = photoLibraryManager
        self.deleteBatchManager = deleteBatchManager
        self.redactionService = redactionService
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Image at the top (fixed, not scrollable)
                if let image = fullSizeImage ?? result.thumbnail {
                    GeometryReader { geometry in
                        ZStack {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width)

                            // Overlay bounding boxes
                            ForEach(result.detectedRegions) { region in
                                BoundingBoxOverlay(
                                    region: region,
                                    imageSize: image.size,
                                    frameWidth: geometry.size.width
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 300)
                        .overlay {
                            ProgressView()
                        }
                }

                // Scrollable details below
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Detection info section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Detection Results")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 8) {
                                Label(result.reason, systemImage: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)

                                if let score = result.privacyScore {
                                    HStack {
                                        Text("Privacy Risk Score:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(String(format: "%.0f%%", score * 100))")
                                            .fontWeight(.semibold)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            if !result.detectedRegions.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Detected Regions")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    ForEach(result.detectedRegions) { region in
                                        HStack {
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 8, height: 8)

                                            Text(region.label)
                                                .font(.subheadline)

                                            Spacer()

                                            Text("\(String(format: "%.0f%%", region.confidence * 100))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        // Gemini explanation
                        VStack(alignment: .leading, spacing: 8) {
                            Label("AI Explanation", systemImage: "sparkles")
                                .font(.headline)

                            if let explanation = result.geminiExplanation {
                                Text(explanation)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("No explanation available")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Redaction hint
                        if result.asset != nil {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Swipe Down to Blur Text", systemImage: "arrow.down")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)

                                Text("Pull down on the card to automatically detect and blur all text in this image")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Deletion queue status
                        if deleteBatchManager.stagedAssetIds.count > 0 {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.red)

                                Text("\(deleteBatchManager.stagedAssetIds.count) photo(s) queued for deletion")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Spacer()
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                }
            }
            .offset(y: max(0, dragOffset))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { _ in
                        if dragOffset > redactionSwipeThreshold {
                            performRedaction()
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                dragOffset = 0
                            }
                        }
                    }
            )

            // Blue indicator at bottom
            if dragOffset > 0 {
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.blue)
                        .frame(height: 4)
                        .opacity(min(1.0, dragOffset / redactionSwipeThreshold))
                }
                .allowsHitTesting(false)
            }

            // Progress overlay
            if isRedacting {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(.circular)
                        .tint(.white)

                    Text("Redacting text…")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(32)
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }
        }
        .task {
            await loadFullSizeImage()
        }
        .alert("Redaction Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(redactionError ?? "An error occurred during redaction")
        }
    }

    private func loadFullSizeImage() async {
        // Use cached thumbnail if no asset (preview mode)
        if let thumbnail = result.thumbnail {
            fullSizeImage = thumbnail
            return
        }

        guard let asset = result.asset else { return }
        let targetSize = CGSize(width: 1024, height: 1024)
        fullSizeImage = await photoLibraryManager.loadThumbnail(for: asset, targetSize: targetSize)
    }

    private func performRedaction() {
        guard let asset = result.asset else {
            redactionError = "Cannot redact preview images"
            showError = true
            withAnimation {
                dragOffset = 0
            }
            return
        }

        isRedacting = true
        dragOffset = 0

        Task {
            do {
                let newAsset = try await redactionService.redactAndReplace(asset: asset) { redactedAsset in
                    // Queue the redacted photo for deletion
                    deleteBatchManager.stage(redactedAsset.localIdentifier)
                }

                await MainActor.run {
                    isRedacting = false

                    // Update the view with the new redacted asset
                    Task {
                        let targetSize = CGSize(width: 1024, height: 1024)
                        fullSizeImage = await photoLibraryManager.loadThumbnail(
                            for: newAsset,
                            targetSize: targetSize
                        )
                    }

                    // Haptic success feedback
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch RedactionError.noTextFound {
                await MainActor.run {
                    isRedacting = false
                    redactionError = "No text found in this image"
                    showError = true
                }
            } catch RedactionError.deleteFailed {
                await MainActor.run {
                    isRedacting = false
                    redactionError = "Redacted copy saved, but original could not be deleted. Both copies remain in your library."
                    showError = true
                }
            } catch {
                await MainActor.run {
                    isRedacting = false
                    redactionError = "Failed to redact: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// Helper for bounding box overlay
private struct BoundingBoxOverlay: View {
    let region: DetectedRegion
    let imageSize: CGSize
    let frameWidth: CGFloat

    var body: some View {
        let scale = frameWidth / imageSize.width
        let rect = CGRect(
            x: region.normalizedRect.origin.x * imageSize.width * scale,
            y: region.normalizedRect.origin.y * imageSize.height * scale,
            width: region.normalizedRect.width * imageSize.width * scale,
            height: region.normalizedRect.height * imageSize.height * scale
        )

        Rectangle()
            .stroke(Color.red, lineWidth: 2)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
    }
}


#Preview("Swipe Card - Flagged") {
    SwipeCardView(
        content: {
            DetectionResultCard(
                result: .mockFlagged,
                photoLibraryManager: PhotoLibraryManager(),
                deleteBatchManager: DeleteBatchManager()
            )
        },
        onDelete: { print("Deleted") },
        onKeep: { print("Kept") }
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .ignoresSafeArea()
}


#Preview("Detection Result Card Only") {
    DetectionResultCard(
        result: DetectionResult.mockFlagged,
        photoLibraryManager: PhotoLibraryManager(),
        deleteBatchManager: DeleteBatchManager()
    )
    .padding()
}

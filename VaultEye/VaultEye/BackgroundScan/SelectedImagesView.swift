//
//  SelectedImagesView.swift
//  VaultEye
//
//  Display selected/matched images from background scan
//

import SwiftUI
import Photos

struct SelectedImagesView: View {
    @EnvironmentObject var scanManager: BackgroundScanManager
    @State private var selectedAssets: [PHAsset] = []
    @State private var thumbnails: [String: UIImage] = [:]

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 8)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if selectedAssets.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(selectedAssets, id: \.localIdentifier) { asset in
                                ThumbnailCell(
                                    asset: asset,
                                    thumbnail: thumbnails[asset.localIdentifier]
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Matched Images")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadSelectedAssets()
            }
            .refreshable {
                await loadSelectedAssets()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Matched Images")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Run a scan to find images that match your criteria")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private func loadSelectedAssets() async {
        let assetIDs = scanManager.getSelectedAssetIDs()

        guard !assetIDs.isEmpty else {
            selectedAssets = []
            return
        }

        // Fetch assets
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: assetIDs, options: nil)
        var assets: [PHAsset] = []

        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }

        await MainActor.run {
            self.selectedAssets = assets
        }

        // Load thumbnails
        for asset in assets {
            if thumbnails[asset.localIdentifier] == nil {
                if let thumbnail = await PhotoAccess.requestUIImage(
                    for: asset,
                    targetSize: CGSize(width: 300, height: 300)
                ) {
                    await MainActor.run {
                        thumbnails[asset.localIdentifier] = thumbnail
                    }
                }
            }
        }
    }
}

// MARK: - Thumbnail Cell

private struct ThumbnailCell: View {
    let asset: PHAsset
    let thumbnail: UIImage?

    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        ProgressView()
                    }
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview {
    SelectedImagesView()
        .environmentObject(BackgroundScanManager())
}

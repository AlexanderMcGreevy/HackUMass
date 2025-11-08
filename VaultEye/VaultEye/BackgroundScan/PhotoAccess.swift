//
//  PhotoAccess.swift
//  VaultEye
//
//  Photo library access and image loading utilities
//

import Photos
import UIKit

final class PhotoAccess {

    // MARK: - Permission Request

    static func requestAccess() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return newStatus == .authorized || newStatus == .limited
        default:
            return false
        }
    }

    static func isAuthorized() -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        return status == .authorized || status == .limited
    }

    // MARK: - Fetch Assets

    static func fetchAllImageAssets() -> [String] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        var assetIDs: [String] = []

        fetchResult.enumerateObjects { asset, _, _ in
            assetIDs.append(asset.localIdentifier)
        }

        return assetIDs
    }

    static func fetchAsset(byLocalIdentifier identifier: String) -> PHAsset? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        return fetchResult.firstObject
    }

    // MARK: - Image Loading

    static func requestCGImage(for asset: PHAsset, targetSize: CGSize = CGSize(width: 1024, height: 1024)) async throws -> CGImage? {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = false
            options.isSynchronous = false
            options.resizeMode = .fast

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }

                if let image = image, let cgImage = image.cgImage {
                    continuation.resume(returning: cgImage)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    static func requestUIImage(for asset: PHAsset, targetSize: CGSize = CGSize(width: 300, height: 300)) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.isNetworkAccessAllowed = false
            options.isSynchronous = false

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}

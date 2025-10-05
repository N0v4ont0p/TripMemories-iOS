import Foundation
import Photos
import CoreLocation

#if os(macOS)
import AppKit
typealias PlatformImage = NSImage
#else
import UIKit
typealias PlatformImage = UIImage
#endif

/// Handles all photo library operations
class PhotoLibraryService: ObservableObject {
    static let shared = PhotoLibraryService()
    
    private let imageManager = PHCachingImageManager()
    private let thumbnailSize = CGSize(width: 300, height: 300)
    
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    func requestAuthorization() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            self.authorizationStatus = status
        }
    }
    
    // MARK: - Fetch Photos
    
    /// Fetches ALL photos with location data from the library (including iCloud)
    func fetchAllPhotos() async -> [Photo] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced, .typeCloudShared]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var photos: [Photo] = []
        fetchResult.enumerateObjects { asset, _, _ in
            // Only include photos with location data
            if asset.location != nil {
                photos.append(Photo(asset: asset))
            }
        }
        
        print("📸 Fetched \(photos.count) photos with location data")
        return photos
    }
    
    // MARK: - Load Thumbnails
    
    /// Loads a single thumbnail for a photo
    func loadThumbnail(for photo: Photo) async -> PlatformImage? {
        guard let asset = photo.asset else { return nil }
        
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            
            // Add timeout for iCloud downloads
            options.progressHandler = { progress, error, stop, info in
                if let error = error {
                    print("⚠️ iCloud download error: \(error.localizedDescription)")
                }
            }
            
            var hasResumed = false
            var requestID: PHImageRequestID?
            
            requestID = imageManager.requestImage(
                for: asset,
                targetSize: thumbnailSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                guard !hasResumed else { return }
                
                // Check if this is the final image (not degraded)
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                let hasError = (info?[PHImageErrorKey] as? Error) != nil
                
                // Accept degraded image if there's an error or after timeout
                if !isDegraded || hasError || isCancelled {
                    hasResumed = true
                    continuation.resume(returning: image)
                }
            }
            
            // Set timeout for iCloud downloads (10 seconds)
            Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                if !hasResumed {
                    hasResumed = true
                    if let id = requestID {
                        imageManager.cancelImageRequest(id)
                    }
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    /// Loads thumbnails for multiple photos in batches with optimized concurrency
    func loadThumbnails(for photos: [Photo]) async -> [String: PlatformImage] {
        var thumbnails: [String: PlatformImage] = [:]
        
        // Optimize batch size based on iCloud status
        let batchSize = 20
        var index = 0
        
        print("📷 Starting to load \(photos.count) thumbnails...")
        
        while index < photos.count {
            let endIndex = min(index + batchSize, photos.count)
            let batch = Array(photos[index..<endIndex])
            
            // Use task group with limited concurrency
            await withTaskGroup(of: (String, PlatformImage?).self) { group in
                for photo in batch {
                    group.addTask { [weak self] in
                        guard let self = self else { return (photo.id, nil) }
                        let thumbnail = await self.loadThumbnail(for: photo)
                        return (photo.id, thumbnail)
                    }
                }
                
                for await (photoID, thumbnail) in group {
                    if let thumbnail = thumbnail {
                        thumbnails[photoID] = thumbnail
                    }
                }
            }
            
            index = endIndex
            let progress = Int((Double(thumbnails.count) / Double(photos.count)) * 100)
            print("📷 Progress: \(thumbnails.count)/\(photos.count) (\(progress)%)")
            
            // Small delay between batches to prevent overwhelming the system
            if index < photos.count {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        }
        
        print("✅ Loaded \(thumbnails.count) thumbnails successfully")
        return thumbnails
    }
    
    /// Preload thumbnails for visible photos only (for better performance)
    func preloadThumbnails(for photos: [Photo], limit: Int = 50) async -> [String: PlatformImage] {
        let photosToLoad = Array(photos.prefix(limit))
        return await loadThumbnails(for: photosToLoad)
    }
}

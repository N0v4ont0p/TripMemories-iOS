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
            options.deliveryMode = .opportunistic
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            
            var hasResumed = false
            
            imageManager.requestImage(
                for: asset,
                targetSize: thumbnailSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                guard !hasResumed else { return }
                
                // Check if this is the final image (not degraded)
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                
                if !isDegraded {
                    hasResumed = true
                    #if os(macOS)
                    continuation.resume(returning: image)
                    #else
                    continuation.resume(returning: image)
                    #endif
                }
            }
        }
    }
    
    /// Loads thumbnails for multiple photos in batches
    func loadThumbnails(for photos: [Photo]) async -> [String: PlatformImage] {
        var thumbnails: [String: PlatformImage] = [:]
        
        // Process in batches to avoid memory issues
        let batchSize = 15
        var index = 0
        
        while index < photos.count {
            let endIndex = min(index + batchSize, photos.count)
            let batch = Array(photos[index..<endIndex])
            
            await withTaskGroup(of: (String, PlatformImage?).self) { group in
                for photo in batch {
                    group.addTask {
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
            print("📷 Loaded \(thumbnails.count)/\(photos.count) thumbnails")
        }
        
        return thumbnails
    }
}

import Foundation
import Photos
import UIKit

class PhotoLibraryService: ObservableObject {
    static let shared = PhotoLibraryService()
    
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var isLoading: Bool = false
    @Published var loadingProgress: String = ""
    @Published var loadingError: String?
    
    private init() {
        self.authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    func requestAuthorization() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            self.authorizationStatus = status
        }
    }
    
    func fetchPhotos() async -> [Photo] {
        await MainActor.run {
            self.isLoading = true
            self.loadingError = nil
            self.loadingProgress = "Starting..."
        }
        
        // Increased timeout to 120 seconds for very large libraries
        let result = await withTaskGroup(of: [Photo]?.self) { group in
            // Fetch photos task with progress
            group.addTask { [weak self] in
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                
                // Fetch all image assets
                let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                let totalCount = assets.count
                
                print("📸 Found \(totalCount) photos in library")
                
                await MainActor.run {
                    self?.loadingProgress = "Found \(totalCount) photos"
                }
                
                var photos: [Photo] = []
                photos.reserveCapacity(totalCount)
                
                var processedCount = 0
                var photosWithLocation = 0
                var photosWithoutLocation = 0
                
                // Enumerate all assets
                assets.enumerateObjects { asset, index, _ in
                    // Extract location from asset with detailed logging
                    let location: Photo.Location?
                    if let assetLocation = asset.location {
                        let lat = assetLocation.coordinate.latitude
                        let lon = assetLocation.coordinate.longitude
                        
                        // Validate coordinates
                        if lat != 0.0 || lon != 0.0 {
                            location = Photo.Location(latitude: lat, longitude: lon)
                            photosWithLocation += 1
                            
                            // Debug: Print first few locations
                            if photosWithLocation <= 5 {
                                print("📍 Photo \(index): Location (\(lat), \(lon))")
                            }
                        } else {
                            location = nil
                            photosWithoutLocation += 1
                        }
                    } else {
                        location = nil
                        photosWithoutLocation += 1
                    }
                    
                    // Use creation date or modification date
                    let photoDate = asset.creationDate ?? asset.modificationDate ?? Date()
                    
                    let photo = Photo(
                        id: asset.localIdentifier,
                        date: photoDate,
                        location: location
                    )
                    photos.append(photo)
                    
                    processedCount += 1
                    
                    // Update progress every 50 photos
                    if processedCount % 50 == 0 {
                        Task { @MainActor in
                            self?.loadingProgress = "Processing \(processedCount) of \(totalCount)..."
                        }
                    }
                }
                
                print("✅ Loaded \(photos.count) photos: \(photosWithLocation) with location, \(photosWithoutLocation) without")
                
                await MainActor.run {
                    self?.loadingProgress = "✓ Loaded \(photos.count) photos (\(photosWithLocation) with location)"
                }
                
                return photos
            }
            
            // Timeout task (120 seconds for very large libraries)
            group.addTask {
                try? await Task.sleep(nanoseconds: 120_000_000_000)
                return nil
            }
            
            // Return first result (either photos or timeout)
            if let photos = await group.next() {
                group.cancelAll()
                return photos
            }
            return nil
        }
        
        await MainActor.run {
            self.isLoading = false
            if result == nil {
                self.loadingError = "Photo library loading timed out after 120 seconds. You may have a very large photo library. Try restarting the app."
                self.loadingProgress = ""
                print("❌ Photo loading timed out!")
            }
        }
        
        return result ?? []
    }
    
    func loadThumbnail(for photoID: String) async -> UIImage? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [photoID], options: nil)
        guard let asset = fetchResult.firstObject else { return nil }
        
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        
        return await withCheckedContinuation { continuation in
            manager.requestImage(
                for: asset,
                targetSize: CGSize(width: 300, height: 300),
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
    
    func loadFullImage(for photoID: String) async -> UIImage? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [photoID], options: nil)
        guard let asset = fetchResult.firstObject else { return nil }
        
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        return await withCheckedContinuation { continuation in
            manager.requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
    
    func createAlbum(name: String, photoIDs: [String]) async {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: photoIDs, options: nil)
        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        guard !assets.isEmpty else { return }
        
        // Step 1: Create the album
        var albumPlaceholder: PHObjectPlaceholder?
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
                albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
            }
        } catch {
            return
        }
        
        // Step 2: Add photos to the created album
        guard let placeholder = albumPlaceholder,
              let album = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil).firstObject else {
            return
        }
        
        try? await PHPhotoLibrary.shared().performChanges {
            if let albumChangeRequest = PHAssetCollectionChangeRequest(for: album) {
                albumChangeRequest.addAssets(assets as NSArray)
            }
        }
    }
}



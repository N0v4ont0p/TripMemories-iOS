import Foundation
import Photos
import UIKit

class PhotoLibraryService: ObservableObject {
    static let shared = PhotoLibraryService()
    
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var isLoading: Bool = false
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
        }
        
        // Add timeout for Mac Catalyst XPC issues
        let result = await withTaskGroup(of: [Photo]?.self) { group in
            // Fetch photos task
            group.addTask {
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                
                let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                var photos: [Photo] = []
                
                assets.enumerateObjects { asset, _, _ in
                    let location: Photo.Location? = if let loc = asset.location {
                        Photo.Location(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
                    } else {
                        nil
                    }
                    
                    let photo = Photo(
                        id: asset.localIdentifier,
                        date: asset.creationDate ?? Date(),
                        location: location
                    )
                    photos.append(photo)
                }
                
                return photos
            }
            
            // Timeout task (10 seconds)
            group.addTask {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
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
                self.loadingError = "Photo library access timed out. This may be a Mac Catalyst compatibility issue."
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



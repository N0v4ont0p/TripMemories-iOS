import Foundation
import Photos
import UIKit

class PhotoLibraryService: ObservableObject {
    static let shared = PhotoLibraryService()
    
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    
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
        
        try? await PHPhotoLibrary.shared().performChanges {
            let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
            if let placeholder = createAlbumRequest.placeholderForCreatedAssetCollection,
               let albumChangeRequest = PHAssetCollectionChangeRequest(for: placeholder) {
                albumChangeRequest.addAssets(assets as NSArray)
            }
        }
    }
}


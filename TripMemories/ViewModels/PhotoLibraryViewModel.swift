import Foundation
import Photos
import UIKit

@MainActor
class PhotoLibraryViewModel: ObservableObject {
    @Published var photos: [Photo] = []
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var thumbnails: [String: UIImage] = [:]
    @Published var loadingProgress: Double = 0
    
    private let photoService = PhotoLibraryService.shared
    private var loadingTasks: [String: Task<Void, Never>] = [:]
    private let thumbnailCache = NSCache<NSString, UIImage>()
    
    func requestAuthorization() async {
        await photoService.requestAuthorization()
        authorizationStatus = photoService.authorizationStatus
    }
    
    func fetchPhotos() async {
        isLoading = true
        photos = await photoService.fetchPhotos()
        isLoading = false
    }
    
    func loadThumbnail(for photoID: String) async {
        // Check memory cache first
        if thumbnails[photoID] != nil { return }
        
        // Check NSCache
        if let cached = thumbnailCache.object(forKey: photoID as NSString) {
            thumbnails[photoID] = cached
            return
        }
        
        // Avoid duplicate loading
        if loadingTasks[photoID] != nil { return }
        
        let task = Task {
            if let image = await photoService.loadThumbnail(for: photoID) {
                thumbnails[photoID] = image
                thumbnailCache.setObject(image, forKey: photoID as NSString)
            }
            loadingTasks.removeValue(forKey: photoID)
        }
        
        loadingTasks[photoID] = task
        await task.value
    }
    
    func preloadThumbnails(for photoIDs: [String]) async {
        let batchSize = 10
        let batches = stride(from: 0, to: photoIDs.count, by: batchSize).map {
            Array(photoIDs[$0..<min($0 + batchSize, photoIDs.count)])
        }
        
        for (index, batch) in batches.enumerated() {
            await withTaskGroup(of: Void.self) { group in
                for photoID in batch {
                    group.addTask {
                        await self.loadThumbnail(for: photoID)
                    }
                }
            }
            
            loadingProgress = Double(index + 1) / Double(batches.count)
        }
    }
    
    func clearCache() {
        thumbnails.removeAll()
        thumbnailCache.removeAllObjects()
        loadingTasks.values.forEach { $0.cancel() }
        loadingTasks.removeAll()
    }
}


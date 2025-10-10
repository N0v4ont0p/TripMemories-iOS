import Foundation
import Photos
import UIKit

@MainActor
class PhotoLibraryViewModel: ObservableObject {
    @Published var photos: [Photo] = []
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var thumbnails: [String: UIImage] = [:]
    
    private let photoService = PhotoLibraryService.shared
    
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
        if thumbnails[photoID] != nil { return }
        
        if let image = await photoService.loadThumbnail(for: photoID) {
            thumbnails[photoID] = image
        }
    }
}


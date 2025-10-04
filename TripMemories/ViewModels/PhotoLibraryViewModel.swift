import Foundation
import Photos
import SwiftUI

/// Manages photo library state and operations
@MainActor
class PhotoLibraryViewModel: ObservableObject {
    @Published var photos: [Photo] = []
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    
    private let photoService = PhotoLibraryService.shared
    
    init() {
        checkAuthorization()
    }
    
    func checkAuthorization() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    func requestAuthorization() async {
        await photoService.requestAuthorization()
        authorizationStatus = photoService.authorizationStatus
    }
    
    func fetchPhotos() async {
        isLoading = true
        photos = await photoService.fetchAllPhotos()
        isLoading = false
    }
}

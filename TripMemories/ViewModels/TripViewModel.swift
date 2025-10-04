import Foundation
import SwiftUI

/// Manages trip state and operations
@MainActor
class TripViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var thumbnails: [String: PlatformImage] = [:]
    @Published var isOrganizing = false
    @Published var organizingProgress: Double = 0
    
    private let clusteringService = TripClusteringService.shared
    private let photoService = PhotoLibraryService.shared
    private let persistenceService = PersistenceService.shared
    
    init() {
        loadCachedTrips()
    }
    
    func loadCachedTrips() {
        if let cachedTrips = persistenceService.loadTrips() {
            trips = cachedTrips
            print("✅ Loaded \(cachedTrips.count) cached trips")
        }
    }
    
    func organizeTrips(photos: [Photo], settings: UserSettings?) async {
        isOrganizing = true
        organizingProgress = 0
        
        // Cluster photos into trips
        let newTrips = await clusteringService.clusterPhotos(photos, userSettings: settings)
        
        organizingProgress = 0.5
        
        // Load thumbnails for all trip photos
        var allPhotos: [Photo] = []
        for trip in newTrips {
            let tripPhotos = photos.filter { trip.photoIDs.contains($0.id) }
            allPhotos.append(contentsOf: tripPhotos)
        }
        
        let loadedThumbnails = await photoService.loadThumbnails(for: allPhotos)
        
        organizingProgress = 1.0
        
        // Update state
        trips = newTrips
        thumbnails = loadedThumbnails
        
        // Save to cache
        try? persistenceService.saveTrips(newTrips)
        
        isOrganizing = false
    }
    
    func clearTrips() {
        trips = []
        thumbnails = [:]
        try? persistenceService.clearTrips()
    }
}

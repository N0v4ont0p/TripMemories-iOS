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
    
    // MARK: - Trip Editing
    
    func toggleFavorite(trip: Trip) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index].isFavorite.toggle()
            saveTrips()
        }
    }
    
    func updateTripTitle(trip: Trip, newTitle: String) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index].customTitle = newTitle.isEmpty ? nil : newTitle
            saveTrips()
        }
    }
    
    func updateTripCategory(trip: Trip, newCategory: TripCategory) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index].category = newCategory
            saveTrips()
        }
    }
    
    func updateTripNotes(trip: Trip, newNotes: String) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index].notes = newNotes.isEmpty ? nil : newNotes
            saveTrips()
        }
    }
    
    func deleteTrip(trip: Trip) {
        trips.removeAll { $0.id == trip.id }
        saveTrips()
    }
    
    func mergeTrips(_ trip1: Trip, _ trip2: Trip, newTitle: String? = nil) {
        guard let index1 = trips.firstIndex(where: { $0.id == trip1.id }),
              let index2 = trips.firstIndex(where: { $0.id == trip2.id }) else {
            return
        }
        
        // Create merged trip
        let allPhotoIDs = Array(Set(trip1.photoIDs + trip2.photoIDs))
        let earliestDate = min(trip1.startDate, trip2.startDate)
        let latestDate = max(trip1.endDate, trip2.endDate)
        
        var mergedTrip = Trip(
            title: newTitle ?? trip1.title,
            startDate: earliestDate,
            endDate: latestDate,
            locationName: trip1.locationName,
            photos: [], // We'll use photoIDs directly
            centroid: trip1.centroid,
            isFavorite: trip1.isFavorite || trip2.isFavorite,
            category: trip1.category
        )
        
        // Manually set photoIDs
        trips[index1] = mergedTrip
        trips.remove(at: index2)
        
        saveTrips()
    }
    
    private func saveTrips() {
        try? persistenceService.saveTrips(trips)
    }
}

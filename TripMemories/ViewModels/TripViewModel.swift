import Foundation
import CoreLocation

@MainActor
class TripViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var isOrganizing = false
    
    private let clusteringService = TripClusteringService.shared
    private let persistenceService = PersistenceService.shared
    
    init() {
        loadTrips()
    }
    
    func organizePhotos(photos: [Photo], homeLocation: CLLocation?) async {
        print("🚀 Starting photo organization...")
        print("📊 Input: \(photos.count) photos, home location: \(homeLocation != nil ? "set" : "not set")")
        
        // Ensure we always reset isOrganizing
        defer {
            isOrganizing = false
            print("🏁 Organizing flag reset")
        }
        
        isOrganizing = true
        
        do {
            // Run clustering OFF the main thread
            let newTrips = await Task.detached(priority: .userInitiated) {
                print("⚙️ Running clustering on background thread...")
                return await TripClusteringService.shared.clusterPhotosIntoTrips(photos: photos, homeLocation: homeLocation)
            }.value
            
            // Update UI on main thread
            print("💾 Saving \(newTrips.count) trips...")
            trips = newTrips
            saveTrips()
            print("✅ Organization complete!")
        } catch {
            print("❌ Error during organization: \(error)")
        }
    }
    
    func toggleFavorite(trip: Trip) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index].isFavorite.toggle()
            saveTrips()
        }
    }
    
    func updateTripTitle(trip: Trip, newTitle: String) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index].title = newTitle
            saveTrips()
        }
    }
    
    func clearAllTrips() {
        print("🗑️ Clearing all trips...")
        trips = []
        saveTrips()
        print("✅ All trips cleared!")
    }
    
    func refreshUnknownLocations(photos: [Photo]) async {
        print("🔄 Refreshing unknown locations...")
        isOrganizing = true
        
        defer {
            isOrganizing = false
            print("🏁 Refresh complete")
        }
        
        var updatedTrips = trips
        var refreshCount = 0
        
        for (index, trip) in updatedTrips.enumerated() {
            if trip.locationName == "Unknown Location" {
                // Get photos for this trip
                let tripPhotos = photos.filter { trip.photoIDs.contains($0.id) }
                guard !tripPhotos.isEmpty else {
                    continue
                }
                
                let centerPhoto = tripPhotos[tripPhotos.count / 2]
                guard let location = centerPhoto.location else {
                    continue
                }
                
                // Try to geocode again
                let locationName = await clusteringService.refreshLocationName(for: location.toCLLocation())
                
                if locationName != "Unknown Location" {
                    updatedTrips[index].locationName = locationName
                    updatedTrips[index].title = clusteringService.generateTitlePublic(locationName: locationName, startDate: trip.startDate)
                    refreshCount += 1
                    print("✅ Refreshed: \(locationName)")
                }
            }
        }
        
        trips = updatedTrips
        saveTrips()
        print("✅ Refreshed \(refreshCount) locations")
    }
    
    private func saveTrips() {
        try? persistenceService.saveTrips(trips)
    }
    
    private func loadTrips() {
        if let savedTrips = persistenceService.loadTrips() {
            trips = savedTrips
        }
    }
}


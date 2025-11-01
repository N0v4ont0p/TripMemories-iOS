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
        isOrganizing = true
        
        // Run clustering OFF the main thread
        let newTrips = await Task.detached(priority: .userInitiated) {
            print("⚙️ Running clustering on background thread...")
            return await TripClusteringService.shared.clusterPhotosIntoTrips(photos: photos, homeLocation: homeLocation)
        }.value
        
        // Update UI on main thread
        print("💾 Saving \(newTrips.count) trips...")
        trips = newTrips
        saveTrips()
        isOrganizing = false
        print("✅ Organization complete!")
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
    
    private func saveTrips() {
        try? persistenceService.saveTrips(trips)
    }
    
    private func loadTrips() {
        if let savedTrips = persistenceService.loadTrips() {
            trips = savedTrips
        }
    }
}


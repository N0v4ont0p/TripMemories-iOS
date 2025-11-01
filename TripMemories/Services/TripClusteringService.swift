import Foundation
import CoreLocation

class TripClusteringService {
    static let shared = TripClusteringService()
    
    private let minTripDistance: Double = 30_000 // 30km from home
    private let clusterRadius: Double = 150_000 // 150km grouping radius
    private let maxDayGap: Int = 4 // Max days between photos in same trip
    
    func clusterPhotosIntoTrips(photos: [Photo], homeLocation: CLLocation?) async -> [Trip] {
        print("🗺️ Clustering: Total photos = \(photos.count)")
        
        // Filter photos with location
        let photosWithLocation = photos.filter { $0.location != nil }
        print("📍 Photos with location: \(photosWithLocation.count)")
        
        guard !photosWithLocation.isEmpty else {
            print("❌ No photos with location data!")
            return []
        }
        
        // Sort by date
        let sortedPhotos = photosWithLocation.sorted { $0.date < $1.date }
        
        // Filter photos far from home
        let tripPhotos: [Photo]
        if let home = homeLocation {
            print("🏠 Home location set: (\(home.coordinate.latitude), \(home.coordinate.longitude))")
            tripPhotos = sortedPhotos.filter { photo in
                guard let loc = photo.location else { return false }
                let distance = home.distance(from: loc.toCLLocation())
                return distance > minTripDistance
            }
            print("✈️ Photos far from home (>30km): \(tripPhotos.count)")
        } else {
            print("⚠️ No home location set, using all photos")
            tripPhotos = sortedPhotos
        }
        
        guard !tripPhotos.isEmpty else {
            print("❌ No trip photos after filtering!")
            return []
        }
        
        // Cluster photos
        var trips: [Trip] = []
        var currentCluster: [Photo] = [tripPhotos[0]]
        
        for i in 1..<tripPhotos.count {
            let photo = tripPhotos[i]
            let lastPhoto = currentCluster.last!
            
            // Check time gap
            let dayGap = Calendar.current.dateComponents([.day], from: lastPhoto.date, to: photo.date).day ?? 0
            
            // Check distance
            let distance = lastPhoto.location!.toCLLocation().distance(from: photo.location!.toCLLocation())
            
            if dayGap <= maxDayGap && distance <= clusterRadius {
                currentCluster.append(photo)
            } else {
                // Create trip from current cluster
                if let trip = await createTrip(from: currentCluster) {
                    trips.append(trip)
                }
                currentCluster = [photo]
            }
        }
        
        // Add last cluster
        if let trip = await createTrip(from: currentCluster) {
            trips.append(trip)
        }
        
        let sortedTrips = trips.sorted { $0.startDate > $1.startDate }
        print("✅ Created \(sortedTrips.count) trips")
        return sortedTrips
    }
    
    private func createTrip(from photos: [Photo]) async -> Trip? {
        guard !photos.isEmpty else { return nil }
        
        let startDate = photos.first!.date
        let endDate = photos.last!.date
        
        // Get location name
        let centerPhoto = photos[photos.count / 2]
        let locationName = await getLocationName(for: centerPhoto.location!.toCLLocation())
        
        let title = generateTitle(locationName: locationName, startDate: startDate)
        
        return Trip(
            title: title,
            startDate: startDate,
            endDate: endDate,
            locationName: locationName,
            photoIDs: photos.map { $0.id }
        )
    }
    
    private func getLocationName(for location: CLLocation) async -> String {
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                // Try to get city, state, country
                if let city = placemark.locality {
                    if let country = placemark.country {
                        return "\(city), \(country)"
                    }
                    return city
                }
                if let state = placemark.administrativeArea {
                    if let country = placemark.country {
                        return "\(state), \(country)"
                    }
                    return state
                }
                if let country = placemark.country {
                    return country
                }
            }
        } catch {
            print("Geocoding error: \(error)")
        }
        
        return "Unknown Location"
    }
    
    private func generateTitle(locationName: String, startDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let monthYear = formatter.string(from: startDate)
        return "\(locationName) - \(monthYear)"
    }
}


import Foundation
import CoreLocation

class TripClusteringService {
    static let shared = TripClusteringService()
    
    private let minTripDistance: Double = 30_000 // 30km from home
    private let clusterRadius: Double = 150_000 // 150km grouping radius
    private let maxDayGap: Int = 4 // Max days between photos in same trip
    
    // Geocoding cache to avoid repeated requests
    private var geocodingCache: [String: String] = [:]
    
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
        print("🔄 Starting clustering...")
        var clusters: [[Photo]] = []
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
                clusters.append(currentCluster)
                currentCluster = [photo]
            }
        }
        
        // Add last cluster
        clusters.append(currentCluster)
        
        print("📦 Created \(clusters.count) clusters, now geocoding locations...")
        print("⏱️ This may take several minutes for large libraries...")
        
        // Create trips from clusters with batched geocoding
        var trips: [Trip] = []
        var successCount = 0
        var failureCount = 0
        
        for (index, cluster) in clusters.enumerated() {
            if let trip = await createTrip(from: cluster) {
                trips.append(trip)
                
                if trip.locationName != "Unknown Location" {
                    successCount += 1
                } else {
                    failureCount += 1
                }
                
                // Progress update every 5 trips
                if (index + 1) % 5 == 0 {
                    print("🌍 Geocoded \(index + 1) of \(clusters.count) trips (✅ \(successCount) success, ❌ \(failureCount) failed)...")
                }
                
                // Longer pause to avoid rate limiting - Apple limits geocoding heavily
                if (index + 1) % 10 == 0 {
                    print("⏸️ Pausing 2 seconds to avoid rate limiting...")
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 second pause every 10 requests
                }
            }
        }
        
        let sortedTrips = trips.sorted { $0.startDate > $1.startDate }
        print("✅ Created \(sortedTrips.count) trips (✅ \(successCount) with location, ❌ \(failureCount) unknown)")
        
        if failureCount > 0 {
            print("⚠️ \(failureCount) trips have 'Unknown Location' - geocoding may have timed out or been rate limited")
        }
        
        return sortedTrips
    }
    
    private func createTrip(from photos: [Photo]) async -> Trip? {
        guard !photos.isEmpty else { return nil }
        
        let startDate = photos.first!.date
        let endDate = photos.last!.date
        
        // Get location name with caching and retry
        let centerPhoto = photos[photos.count / 2]
        let centerLocation = centerPhoto.location!.toCLLocation()
        let locationName = await getLocationName(for: centerLocation)
        
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
        // Create cache key from rounded coordinates (to 2 decimal places)
        let lat = round(location.coordinate.latitude * 100) / 100
        let lon = round(location.coordinate.longitude * 100) / 100
        let cacheKey = "\(lat),\(lon)"
        
        // Check cache first
        if let cached = geocodingCache[cacheKey] {
            return cached
        }
        
        // Try geocoding with retry
        var attempts = 0
        let maxAttempts = 2
        
        while attempts < maxAttempts {
            let geocoder = CLGeocoder()
            
            // Add timeout to geocoding (10 seconds)
            let result = await withTaskGroup(of: String?.self) { group in
                // Geocoding task
                group.addTask {
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
                        print("⚠️ Geocoding error (attempt \(attempts + 1)): \(error.localizedDescription)")
                    }
                    return nil
                }
                
                // Timeout task (10 seconds per geocoding request)
                group.addTask {
                    try? await Task.sleep(nanoseconds: 10_000_000_000)
                    return nil
                }
                
                // Return first result
                if let name = await group.next() {
                    group.cancelAll()
                    return name
                }
                return nil
            }
            
            if let locationName = result {
                // Success! Cache and return
                geocodingCache[cacheKey] = locationName
                return locationName
            }
            
            attempts += 1
            if attempts < maxAttempts {
                // Wait 1 second before retry
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
        
        // All attempts failed
        let unknownLocation = "Unknown Location"
        geocodingCache[cacheKey] = unknownLocation
        return unknownLocation
    }
    
    private func generateTitle(locationName: String, startDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let monthYear = formatter.string(from: startDate)
        return "\(locationName) - \(monthYear)"
    }
}



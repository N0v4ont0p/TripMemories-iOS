import Foundation
import CoreLocation

class TripClusteringService {
    static let shared = TripClusteringService()
    
    private let minTripDistance: Double = 30_000 // 30km from home
    private let clusterRadius: Double = 150_000 // 150km grouping radius
    private let maxDayGap: Int = 4 // Max days between photos in same trip
    
    // Geocoding cache to avoid repeated requests
    private var geocodingCache: [String: String] = [:]
    
    // Rate limiting tracking
    private var requestCount: Int = 0
    private var requestWindowStart: Date = Date()
    private let maxRequestsPerMinute: Int = 45 // Stay under Apple's 50/minute limit
    
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
        print("⏱️ Apple rate limit: 45 requests/minute - this will take ~\(Int(ceil(Double(clusters.count) / 45.0))) minutes")
        
        // Reset rate limiting
        requestCount = 0
        requestWindowStart = Date()
        
        // Create trips from clusters with rate-limited geocoding
        var trips: [Trip] = []
        var successCount = 0
        var failureCount = 0
        
        for (index, cluster) in clusters.enumerated() {
            // Check rate limit before each request
            await enforceRateLimit()
            
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
            }
        }
        
        let sortedTrips = trips.sorted { $0.startDate > $1.startDate }
        print("✅ Created \(sortedTrips.count) trips (✅ \(successCount) with location, ❌ \(failureCount) unknown)")
        
        if failureCount > 0 {
            print("⚠️ \(failureCount) trips have 'Unknown Location' - geocoding may have timed out or failed")
        }
        
        return sortedTrips
    }
    
    private func enforceRateLimit() async {
        // Check if we're at the request limit
        if requestCount >= maxRequestsPerMinute {
            let elapsed = Date().timeIntervalSince(requestWindowStart)
            let waitTime = 60.0 - elapsed
            
            if waitTime > 0 {
                print("⏸️ Rate limit reached (\(requestCount) requests). Waiting \(Int(waitTime)) seconds...")
                try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
            
            // Reset window
            requestCount = 0
            requestWindowStart = Date()
            print("✅ Rate limit reset. Continuing...")
        }
    }
    
    private func createTrip(from photos: [Photo]) async -> Trip? {
        guard !photos.isEmpty else { return nil }
        
        let startDate = photos.first!.date
        let endDate = photos.last!.date
        
        // Get location name with caching and rate limiting
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
        
        // Increment request count
        requestCount += 1
        
        // Try geocoding with retry (only once, to avoid doubling requests)
        let geocoder = CLGeocoder()
        
        // Add timeout to geocoding (15 seconds)
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
                } catch let error as NSError {
                    // Check for rate limit error (kCLErrorDomain error 2)
                    if error.domain == "kCLErrorDomain" && error.code == 2 {
                        print("⚠️ Rate limit error detected, will wait before next request")
                    } else {
                        print("⚠️ Geocoding error: \(error.localizedDescription)")
                    }
                }
                return nil
            }
            
            // Timeout task (15 seconds per geocoding request)
            group.addTask {
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                return nil
            }
            
            // Return first result
            if let name = await group.next() {
                group.cancelAll()
                return name
            }
            return nil
        }
        
        let locationName = result ?? "Unknown Location"
        
        // Cache the result
        geocodingCache[cacheKey] = locationName
        
        return locationName
    }
    
    func refreshLocationName(for location: CLLocation) async -> String {
        // Clear cache for this location to force fresh request
        let lat = round(location.coordinate.latitude * 100) / 100
        let lon = round(location.coordinate.longitude * 100) / 100
        let cacheKey = "\(lat),\(lon)"
        geocodingCache.removeValue(forKey: cacheKey)
        
        // Wait for rate limit
        await enforceRateLimit()
        
        // Get fresh location name
        return await getLocationName(for: location)
    }
    
    func generateTitlePublic(locationName: String, startDate: Date) -> String {
        return generateTitle(locationName: locationName, startDate: startDate)
    }
    
    private func generateTitle(locationName: String, startDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let monthYear = formatter.string(from: startDate)
        return "\(locationName) - \(monthYear)"
    }
}



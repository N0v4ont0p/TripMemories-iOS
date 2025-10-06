import Foundation
import CoreLocation

/// Intelligently clusters photos into trips
class TripClusteringService {
    static let shared = TripClusteringService()
    
    // MARK: - Configuration
    
    private let minTripDistance: CLLocationDistance = 30_000 // 30km from home (reduced from 50km)
    private let locationGroupingRadius: CLLocationDistance = 150_000 // 150km radius (increased from 100km)
    private let maxDayGap: TimeInterval = 4 * 24 * 60 * 60 // 4 days (increased from 3 days)
    private let minPhotosPerTrip = 2
    private let nearbyTripMergeRadius: CLLocationDistance = 200_000 // 200km for merging nearby trips
    
    private var geocodingCache: [String: (city: String, country: String)] = [:]
    private let geocoder = CLGeocoder()
    
    private init() {
        // Load geocoding cache
        if let cache = PersistenceService.shared.loadGeocodingCache() {
            self.geocodingCache = cache
            print("📍 Loaded geocoding cache with \(cache.count) entries")
        }
    }
    
    // MARK: - Main Clustering Function
    
    func clusterPhotos(_ photos: [Photo], userSettings: UserSettings?) async -> [Trip] {
        print("\n🔄 Starting trip clustering...")
        print("📊 Total photos: \(photos.count)")
        
        guard let homeLocation = userSettings?.homeLocation?.toCLLocation() else {
            print("⚠️ No home location set, cannot filter trips")
            return []
        }
        
        // Step 1: Filter photos that are far from home
        let tripPhotos = photos.filter { photo in
            guard let photoLocation = photo.location?.toCLLocation() else { return false }
            let distance = photoLocation.distance(from: homeLocation)
            return distance >= minTripDistance
        }
        
        print("✈️ Found \(tripPhotos.count) photos far from home (>\(Int(minTripDistance/1000))km)")
        
        if tripPhotos.isEmpty {
            return []
        }
        
        // Step 2: Sort by date
        let sortedPhotos = tripPhotos.sorted { ($0.creationDate ?? Date.distantPast) < ($1.creationDate ?? Date.distantPast) }
        
        // Step 3: Cluster by location and date
        var clusters: [[Photo]] = []
        var currentCluster: [Photo] = []
        
        for photo in sortedPhotos {
            if currentCluster.isEmpty {
                currentCluster.append(photo)
                continue
            }
            
            let shouldAddToCluster = shouldAddPhotoToCluster(photo, cluster: currentCluster)
            
            if shouldAddToCluster {
                currentCluster.append(photo)
            } else {
                if currentCluster.count >= minPhotosPerTrip {
                    clusters.append(currentCluster)
                }
                currentCluster = [photo]
            }
        }
        
        // Add last cluster
        if currentCluster.count >= minPhotosPerTrip {
            clusters.append(currentCluster)
        }
        
        print("📦 Created \(clusters.count) raw clusters")
        
        // Step 4: Merge nearby clusters
        let mergedClusters = mergeNearbyClusters(clusters)
        print("🔗 Merged into \(mergedClusters.count) final clusters")
        
        // Step 5: Convert to trips with geocoding
        var trips: [Trip] = []
        
        for (index, cluster) in mergedClusters.enumerated() {
            print("🌍 Processing cluster \(index + 1)/\(mergedClusters.count)...")
            
            guard let startDate = cluster.first?.creationDate,
                  let endDate = cluster.last?.creationDate else {
                continue
            }
            
            // Calculate centroid
            let centroid = calculateCentroid(for: cluster)
            
            // Geocode location
            let (locationName, codableLocation) = await geocodeLocation(centroid, homeCountry: userSettings?.homeCountry)
            
            // Generate title
            let title = generateTripTitle(startDate: startDate, locationName: locationName)
            
            // Determine category based on duration and location
            let duration = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
            let category = determineCategory(duration: duration + 1, locationName: locationName)
            
            let trip = Trip(
                title: title,
                startDate: startDate,
                endDate: endDate,
                locationName: locationName,
                photos: cluster,
                centroid: codableLocation,
                isFavorite: false,
                category: category,
                notes: nil
            )
            
            trips.append(trip)
            
            // Small delay to avoid rate limiting
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        }
        
        // Save geocoding cache
        try? PersistenceService.shared.saveGeocodingCache(geocodingCache)
        
        print("✅ Created \(trips.count) trips")
        return trips.sorted { $0.startDate > $1.startDate }
    }
    
    // MARK: - Helper Functions
    
    private func shouldAddPhotoToCluster(_ photo: Photo, cluster: [Photo]) -> Bool {
        guard let photoLocation = photo.location?.toCLLocation(),
              let photoDate = photo.creationDate,
              let lastPhoto = cluster.last,
              let lastLocation = lastPhoto.location?.toCLLocation(),
              let lastDate = lastPhoto.creationDate else {
            return false
        }
        
        // Check date gap
        let dayGap = photoDate.timeIntervalSince(lastDate)
        if dayGap > maxDayGap {
            return false
        }
        
        // Check location proximity
        let distance = photoLocation.distance(from: lastLocation)
        if distance > locationGroupingRadius {
            return false
        }
        
        return true
    }
    
    private func mergeNearbyClusters(_ clusters: [[Photo]]) -> [[Photo]] {
        var merged: [[Photo]] = []
        var used = Set<Int>()
        
        for i in 0..<clusters.count {
            if used.contains(i) { continue }
            
            var currentGroup = clusters[i]
            used.insert(i)
            
            for j in (i+1)..<clusters.count {
                if used.contains(j) { continue }
                
                let centroid1 = calculateCentroid(for: currentGroup)
                let centroid2 = calculateCentroid(for: clusters[j])
                
                let distance = centroid1.distance(from: centroid2)
                
                // Use the larger merge radius for combining trips
                if distance <= nearbyTripMergeRadius {
                    // Check if time overlap makes sense (within 30 days)
                    if let date1 = currentGroup.last?.creationDate,
                       let date2 = clusters[j].first?.creationDate {
                        let dayGap = abs(date2.timeIntervalSince(date1)) / (24 * 60 * 60)
                        if dayGap <= 30 {
                            currentGroup.append(contentsOf: clusters[j])
                            used.insert(j)
                        }
                    }
                }
            }
            
            merged.append(currentGroup.sorted { ($0.creationDate ?? Date.distantPast) < ($1.creationDate ?? Date.distantPast) })
        }
        
        return merged
    }
    
    private func calculateCentroid(for photos: [Photo]) -> CLLocation {
        var totalLat: Double = 0
        var totalLon: Double = 0
        var count: Double = 0
        
        for photo in photos {
            if let location = photo.location {
                totalLat += location.latitude
                totalLon += location.longitude
                count += 1
            }
        }
        
        return CLLocation(latitude: totalLat / count, longitude: totalLon / count)
    }
    
    private func geocodeLocation(_ location: CLLocation, homeCountry: String?) async -> (String, CodableLocation?) {
        let cacheKey = "\(Int(location.coordinate.latitude * 10)),\(Int(location.coordinate.longitude * 10))"
        
        // Check cache first
        if let cached = geocodingCache[cacheKey] {
            let locationName = determineLocationName(city: cached.city, country: cached.country, homeCountry: homeCountry)
            return (locationName, CodableLocation(location: location))
        }
        
        // Geocode with retry
        for attempt in 1...3 {
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                
                if let placemark = placemarks.first {
                    let city = placemark.locality ?? placemark.subLocality ?? placemark.administrativeArea ?? "Unknown City"
                    let country = placemark.country ?? "Unknown Country"
                    
                    // Cache result
                    geocodingCache[cacheKey] = (city: city, country: country)
                    
                    // Determine name based on home country
                    let locationName = determineLocationName(city: city, country: country, homeCountry: homeCountry)
                    
                    print("📍 Geocoded: \(locationName) (City: \(city), Country: \(country))")
                    
                    return (locationName, CodableLocation(location: location))
                }
            } catch {
                print("⚠️ Geocoding attempt \(attempt) failed: \(error.localizedDescription)")
                if attempt < 3 {
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                }
            }
        }
        
        return ("Unknown Location", CodableLocation(location: location))
    }
    
    private func determineLocationName(city: String, country: String, homeCountry: String?) -> String {
        // If in home country, show city name
        if let homeCountry = homeCountry, country == homeCountry {
            return city
        }
        
        // For international trips, show country
        // But for large countries like USA, UK, show city + country code
        let largeCities = ["New York", "Los Angeles", "London", "Manchester", "Edinburgh", "Sydney", "Melbourne"]
        if largeCities.contains(city) || country == "United States" || country == "United Kingdom" || country == "Australia" {
            return "\(city), \(getCountryCode(country))"
        }
        
        return country
    }
    
    private func getCountryCode(_ country: String) -> String {
        let codes: [String: String] = [
            "United States": "USA",
            "United Kingdom": "UK",
            "Australia": "AUS",
            "Canada": "CAN",
            "Germany": "DEU",
            "France": "FRA",
            "Italy": "ITA",
            "Spain": "ESP"
        ]
        return codes[country] ?? country
    }
    
    private func determineCategory(duration: Int, locationName: String) -> TripCategory {
        // Smart category determination based on duration and keywords
        let lowercased = locationName.lowercased()
        
        // Check for business keywords
        if lowercased.contains("conference") || lowercased.contains("business") {
            return .business
        }
        
        // Check for adventure keywords
        if lowercased.contains("mountain") || lowercased.contains("hiking") || lowercased.contains("adventure") {
            return .adventure
        }
        
        // Determine by duration
        if duration <= 3 {
            return .weekend
        } else if duration >= 7 {
            return .vacation
        } else {
            return .vacation // Default to vacation for 4-6 days
        }
    }
    
    private func generateTripTitle(startDate: Date, locationName: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let monthYear = formatter.string(from: startDate)
        
        return "\(monthYear) • \(locationName)"
    }
}

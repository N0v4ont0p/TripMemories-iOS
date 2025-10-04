import Foundation

/// Handles all data persistence to disk
class PersistenceService {
    static let shared = PersistenceService()
    
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Trips
    
    func saveTrips(_ trips: [Trip]) throws {
        let url = documentsDirectory.appendingPathComponent("trips.json")
        let data = try encoder.encode(trips)
        try data.write(to: url, options: [.atomic])
        print("✅ Saved \(trips.count) trips to disk")
    }
    
    func loadTrips() -> [Trip]? {
        let url = documentsDirectory.appendingPathComponent("trips.json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode([Trip].self, from: data)
    }
    
    func clearTrips() throws {
        let url = documentsDirectory.appendingPathComponent("trips.json")
        try? fileManager.removeItem(at: url)
        print("🗑️ Cleared trips cache")
    }
    
    // MARK: - Settings
    
    func saveSettings(_ settings: UserSettings) throws {
        let url = documentsDirectory.appendingPathComponent("settings.json")
        let data = try encoder.encode(settings)
        try data.write(to: url, options: [.atomic])
        print("✅ Saved settings to disk")
    }
    
    func loadSettings() -> UserSettings? {
        let url = documentsDirectory.appendingPathComponent("settings.json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(UserSettings.self, from: data)
    }
    
    // MARK: - Geocoding Cache
    
    func saveGeocodingCache(_ cache: [String: (city: String, country: String)]) throws {
        let url = documentsDirectory.appendingPathComponent("geocoding_cache.json")
        let simplifiedCache = cache.mapValues { ["city": $0.city, "country": $0.country] }
        let data = try encoder.encode(simplifiedCache)
        try data.write(to: url, options: [.atomic])
        print("✅ Saved geocoding cache (\(cache.count) entries)")
    }
    
    func loadGeocodingCache() -> [String: (city: String, country: String)]? {
        let url = documentsDirectory.appendingPathComponent("geocoding_cache.json")
        guard let data = try? Data(contentsOf: url),
              let dict = try? decoder.decode([String: [String: String]].self, from: data) else {
            return nil
        }
        
        var cache: [String: (city: String, country: String)] = [:]
        for (key, value) in dict {
            if let city = value["city"], let country = value["country"] {
                cache[key] = (city: city, country: country)
            }
        }
        return cache
    }
}

import Foundation

class PersistenceService {
    static let shared = PersistenceService()
    
    private let tripsKey = "savedTrips"
    private let settingsKey = "userSettings"
    
    private init() {}
    
    func saveTrips(_ trips: [Trip]) throws {
        let data = try JSONEncoder().encode(trips)
        UserDefaults.standard.set(data, forKey: tripsKey)
    }
    
    func loadTrips() -> [Trip]? {
        guard let data = UserDefaults.standard.data(forKey: tripsKey) else { return nil }
        return try? JSONDecoder().decode([Trip].self, from: data)
    }
    
    func saveSettings(_ settings: UserSettings) throws {
        let data = try JSONEncoder().encode(settings)
        UserDefaults.standard.set(data, forKey: settingsKey)
    }
    
    func loadSettings() -> UserSettings? {
        guard let data = UserDefaults.standard.data(forKey: settingsKey) else { return nil }
        return try? JSONDecoder().decode(UserSettings.self, from: data)
    }
}


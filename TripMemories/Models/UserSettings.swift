import Foundation

/// User settings and preferences
struct UserSettings: Codable {
    var homeCity: String?
    var homeLocation: CodableLocation?
    var homeCountry: String?
    var hasCompletedOnboarding: Bool = false
    var lastOrganizedDate: Date?
    
    init() {}
}

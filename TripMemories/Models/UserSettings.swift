import Foundation
import CoreLocation

struct UserSettings: Codable {
    var homeLocation: Location?
    var hasCompletedOnboarding: Bool
    
    struct Location: Codable {
        let latitude: Double
        let longitude: Double
        
        func toCLLocation() -> CLLocation {
            return CLLocation(latitude: latitude, longitude: longitude)
        }
    }
    
    init(homeLocation: Location? = nil, hasCompletedOnboarding: Bool = false) {
        self.homeLocation = homeLocation
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}


import Foundation
import CoreLocation

struct Photo: Identifiable, Codable {
    let id: String
    let date: Date
    let location: Location?
    
    struct Location: Codable {
        let latitude: Double
        let longitude: Double
        
        func toCLLocation() -> CLLocation {
            return CLLocation(latitude: latitude, longitude: longitude)
        }
    }
}


import Foundation
import Photos
import CoreLocation

/// Represents a photo from the user's photo library
struct Photo: Identifiable, Codable {
    let id: String
    let assetIdentifier: String
    let creationDate: Date?
    let location: CodableLocation?
    
    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.assetIdentifier = asset.localIdentifier
        self.creationDate = asset.creationDate
        self.location = asset.location != nil ? CodableLocation(location: asset.location!) : nil
    }
    
    /// Get the PHAsset from the photo library
    var asset: PHAsset? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
        return fetchResult.firstObject
    }
}

/// Codable wrapper for CLLocation
struct CodableLocation: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let timestamp: Date
    
    init(location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.altitude = location.altitude
        self.timestamp = location.timestamp
    }
    
    func toCLLocation() -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: altitude,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: timestamp
        )
    }
}

import Foundation

/// Represents a trip with associated photos
struct Trip: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date
    let locationName: String
    let photoIDs: [String]
    let coverPhotoID: String?
    let centroid: CodableLocation?
    
    init(
        id: UUID = UUID(),
        title: String,
        startDate: Date,
        endDate: Date,
        locationName: String,
        photos: [Photo],
        centroid: CodableLocation?
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.locationName = locationName
        self.photoIDs = photos.map { $0.id }
        self.coverPhotoID = photos.first?.id
        self.centroid = centroid
    }
    
    var photoCount: Int {
        photoIDs.count
    }
    
    var durationDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return max(1, components.day ?? 1)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Trip, rhs: Trip) -> Bool {
        lhs.id == rhs.id
    }
}

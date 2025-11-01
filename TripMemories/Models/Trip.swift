import Foundation

struct Trip: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    let startDate: Date
    let endDate: Date
    var locationName: String
    let photoIDs: [String]
    var isFavorite: Bool
    
    init(id: String = UUID().uuidString,
         title: String,
         startDate: Date,
         endDate: Date,
         locationName: String,
         photoIDs: [String],
         isFavorite: Bool = false) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.locationName = locationName
        self.photoIDs = photoIDs
        self.isFavorite = isFavorite
    }
    
    var photoCount: Int {
        photoIDs.count
    }
    
    var durationDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0 + 1
    }
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}


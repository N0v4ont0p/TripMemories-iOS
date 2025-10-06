import Foundation

/// Represents a trip with associated photos
struct Trip: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    var customTitle: String? // User can override the auto-generated title
    let startDate: Date
    let endDate: Date
    let locationName: String
    let photoIDs: [String]
    let coverPhotoID: String?
    let centroid: CodableLocation?
    var isFavorite: Bool
    var category: TripCategory
    var notes: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        customTitle: String? = nil,
        startDate: Date,
        endDate: Date,
        locationName: String,
        photos: [Photo],
        centroid: CodableLocation?,
        isFavorite: Bool = false,
        category: TripCategory = .vacation,
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.customTitle = customTitle
        self.startDate = startDate
        self.endDate = endDate
        self.locationName = locationName
        self.photoIDs = photos.map { $0.id }
        self.coverPhotoID = photos.first?.id
        self.centroid = centroid
        self.isFavorite = isFavorite
        self.category = category
        self.notes = notes
    }
    
    var displayTitle: String {
        return customTitle ?? title
    }
    
    var photoCount: Int {
        photoIDs.count
    }
    
    var durationDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return max(1, (components.day ?? 0) + 1)
    }
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
            return formatter.string(from: startDate)
        } else {
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }
    }
    
    var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: startDate)
    }
    
    var year: Int {
        return Calendar.current.component(.year, from: startDate)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Trip, rhs: Trip) -> Bool {
        lhs.id == rhs.id
    }
}

/// Trip categories for organization
enum TripCategory: String, Codable, CaseIterable {
    case vacation = "Vacation"
    case business = "Business"
    case weekend = "Weekend"
    case adventure = "Adventure"
    case family = "Family"
    case friends = "Friends"
    case solo = "Solo"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .vacation: return "sun.max.fill"
        case .business: return "briefcase.fill"
        case .weekend: return "calendar.badge.clock"
        case .adventure: return "mountain.2.fill"
        case .family: return "figure.2.and.child.holdinghands"
        case .friends: return "person.3.fill"
        case .solo: return "figure.walk"
        case .other: return "star.fill"
        }
    }
    
    var color: String {
        switch self {
        case .vacation: return "orange"
        case .business: return "blue"
        case .weekend: return "green"
        case .adventure: return "red"
        case .family: return "purple"
        case .friends: return "pink"
        case .solo: return "indigo"
        case .other: return "gray"
        }
    }
}

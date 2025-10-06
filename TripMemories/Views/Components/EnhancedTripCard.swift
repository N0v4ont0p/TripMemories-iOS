import SwiftUI

struct EnhancedTripCard: View {
    let trip: Trip
    let thumbnail: PlatformImage?
    let onToggleFavorite: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack(alignment: .topTrailing) {
                if let thumbnail = thumbnail {
                    Image(platformImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 220)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 220)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                }
                
                // Favorite button
                Button {
                    onToggleFavorite()
                } label: {
                    Image(systemName: trip.isFavorite ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundStyle(trip.isFavorite ? .yellow : .white)
                        .padding(8)
                        .background(.ultraThinMaterial, in: Circle())
                        .shadow(radius: 2)
                }
                .buttonStyle(.plain)
                .padding(12)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 12) {
                // Category badge
                HStack(spacing: 6) {
                    Image(systemName: trip.category.icon)
                        .font(.caption)
                    Text(trip.category.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(trip.category.color), in: Capsule())
                
                // Title
                Text(trip.displayTitle)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                // Date and location
                VStack(alignment: .leading, spacing: 6) {
                    Label(trip.formattedDateRange, systemImage: "calendar")
                        .font(.subheadline)
                    
                    Label(trip.locationName, systemImage: "mappin.circle.fill")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
                
                Divider()
                
                // Stats
                HStack(spacing: 20) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo")
                            .font(.caption)
                        Text("\(trip.photoCount)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text("\(trip.durationDays) day\(trip.durationDays == 1 ? "" : "s")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                }
                .foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }
}

extension Image {
    init(platformImage: PlatformImage) {
        #if os(macOS)
        self.init(nsImage: platformImage)
        #else
        self.init(uiImage: platformImage)
        #endif
    }
}

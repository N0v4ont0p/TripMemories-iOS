import SwiftUI

struct TripCard: View {
    let trip: Trip
    let thumbnail: PlatformImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover image
            Group {
                if let thumbnail = thumbnail {
                    Image(platformImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    placeholderImage
                }
            }
            .frame(height: 220)
            .clipped()
            
            // Info section
            VStack(alignment: .leading, spacing: 12) {
                Text(trip.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.green)
                    
                    Text(trip.locationName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 16) {
                    Label("\(trip.photoCount)", systemImage: "photo.stack")
                    Label("\(trip.durationDays)d", systemImage: "calendar")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
    
    private var placeholderImage: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "photo.stack")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

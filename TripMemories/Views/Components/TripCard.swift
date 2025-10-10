import SwiftUI

struct TripCard: View {
    @EnvironmentObject var photoViewModel: PhotoLibraryViewModel
    @EnvironmentObject var tripViewModel: TripViewModel
    
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover image
            if let firstPhotoID = trip.photoIDs.first,
               let thumbnail = photoViewModel.thumbnails[firstPhotoID] {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(trip.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if trip.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                    }
                }
                
                HStack(spacing: 16) {
                    Label("\(trip.photoCount)", systemImage: "photo")
                    Label("\(trip.durationDays)d", systemImage: "calendar")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                
                Text(trip.formattedDateRange)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        .task {
            if let firstPhotoID = trip.photoIDs.first {
                await photoViewModel.loadThumbnail(for: firstPhotoID)
            }
        }
    }
}


import SwiftUI

struct TripDetailView: View {
    let trip: Trip
    
    @EnvironmentObject var photoViewModel: PhotoLibraryViewModel
    @EnvironmentObject var tripViewModel: TripViewModel
    
    @State private var selectedPhoto: Photo?
    
    private let spacing: CGFloat = 16
    private let minThumbnailSize: CGFloat = 180
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(trip.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 20) {
                            Label("\(trip.photoCount) photos", systemImage: "photo.stack")
                            Label("\(trip.durationDays) days", systemImage: "calendar")
                            Label(trip.locationName, systemImage: "mappin.circle.fill")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, spacing)
                    .padding(.top, spacing)
                    
                    // Photo grid
                    LazyVGrid(columns: calculateColumns(for: geometry.size.width), spacing: spacing) {
                        ForEach(tripPhotos) { photo in
                            if let thumbnail = tripViewModel.thumbnails[photo.id] {
                                Button {
                                    selectedPhoto = photo
                                } label: {
                                    Image(platformImage: thumbnail)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: minThumbnailSize, height: minThumbnailSize)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, spacing)
                }
            }
        }
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo, thumbnail: tripViewModel.thumbnails[photo.id])
        }
    }
    
    private var tripPhotos: [Photo] {
        photoViewModel.photos.filter { trip.photoIDs.contains($0.id) }
    }
    
    private func calculateColumns(for width: CGFloat) -> [GridItem] {
        let availableWidth = width - (spacing * 2)
        let columnCount = max(2, Int(availableWidth / (minThumbnailSize + spacing)))
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }
}

// MARK: - Photo Detail View

struct PhotoDetailView: View {
    let photo: Photo
    let thumbnail: PlatformImage?
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let thumbnail = thumbnail {
                Image(platformImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                    .padding()
                }
                Spacer()
                
                if let date = photo.creationDate {
                    Text(date, style: .date)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding()
                }
            }
        }
    }
}

// MARK: - Platform Image Helper

extension Image {
    init(platformImage: PlatformImage) {
        #if os(macOS)
        self.init(nsImage: platformImage)
        #else
        self.init(uiImage: platformImage)
        #endif
    }
}

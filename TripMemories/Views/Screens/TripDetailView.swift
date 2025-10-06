import SwiftUI
import Photos

struct TripDetailView: View {
    let trip: Trip
    
    @EnvironmentObject var tripViewModel: TripViewModel
    @EnvironmentObject var photoViewModel: PhotoLibraryViewModel
    
    @State private var showEditSheet = false
    @State private var showSlideshow = false
    @State private var showDeleteAlert = false
    @State private var showShareSheet = false
    @State private var selectedPhotoIndex: Int?
    
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 8)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with cover photo
                headerSection
                
                // Trip info
                infoSection
                
                // Notes section
                if let notes = trip.notes, !notes.isEmpty {
                    notesSection(notes)
                }
                
                // Photos grid
                photosSection
            }
        }
        .navigationTitle(trip.displayTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                
                Menu {
                    Button {
                        showSlideshow = true
                    } label: {
                        Label("Slideshow", systemImage: "play.circle")
                    }
                    
                    Button {
                        exportToAlbum()
                    } label: {
                        Label("Export to Album", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        shareTrip()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Trip", systemImage: "trash")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            TripEditView(trip: trip)
        }
        .fullScreenCover(isPresented: $showSlideshow) {
            SlideshowView(trip: trip, photos: tripPhotos)
        }
        .alert("Delete Trip?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                tripViewModel.deleteTrip(trip: trip)
            }
        } message: {
            Text("This will remove the trip album. Your photos will not be deleted.")
        }
    }
    
    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            if let coverPhotoID = trip.coverPhotoID,
               let thumbnail = tripViewModel.thumbnails[coverPhotoID] {
                Image(platformImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 300)
                    .clipped()
            } else {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color(trip.category.color).opacity(0.6), Color(trip.category.color)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(height: 300)
            }
            
            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Title and category
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(trip.category.rawValue, systemImage: trip.category.icon)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(trip.category.color), in: Capsule())
                    
                    if trip.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                    }
                }
                
                Text(trip.displayTitle)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }
    
    private func infoSection() -> some View {
        VStack(spacing: 16) {
            InfoRow(icon: "calendar", title: "Dates", value: trip.formattedDateRange)
            InfoRow(icon: "mappin.circle.fill", title: "Location", value: trip.locationName)
            InfoRow(icon: "photo", title: "Photos", value: "\(trip.photoCount) photos")
            InfoRow(icon: "clock", title: "Duration", value: "\(trip.durationDays) day\(trip.durationDays == 1 ? "" : "s")")
        }
        .padding(.horizontal, 24)
    }
    
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Notes", systemImage: "note.text")
                .font(.headline)
            
            Text(notes)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 24)
    }
    
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Photos (\(trip.photoCount))")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 24)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(tripPhotos.enumerated()), id: \.element.id) { index, photo in
                    Button {
                        selectedPhotoIndex = index
                    } label: {
                        if let thumbnail = tripViewModel.thumbnails[photo.id] {
                            Image(platformImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 150, height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 150, height: 150)
                                .overlay {
                                    ProgressView()
                                }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var tripPhotos: [Photo] {
        photoViewModel.photos.filter { trip.photoIDs.contains($0.id) }
            .sorted { $0.date < $1.date }
    }
    
    private func exportToAlbum() {
        Task {
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    let albumName = trip.displayTitle
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
                    let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
                    
                    if let album = collection.firstObject {
                        // Album exists, add photos
                        let assets = fetchAssets()
                        if let addRequest = PHAssetCollectionChangeRequest(for: album) {
                            addRequest.addAssets(assets as NSFastEnumeration)
                        }
                    } else {
                        // Create new album
                        let createRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                        let assets = fetchAssets()
                        createRequest.addAssets(assets as NSFastEnumeration)
                    }
                }
                print("✅ Exported trip to album: \(trip.displayTitle)")
            } catch {
                print("❌ Failed to export: \(error)")
            }
        }
    }
    
    private func fetchAssets() -> PHFetchResult<PHAsset> {
        let identifiers = trip.photoIDs
        return PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
    }
    
    private func shareTrip() {
        // Implement sharing functionality
        showShareSheet = true
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

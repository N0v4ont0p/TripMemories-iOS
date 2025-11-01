import SwiftUI

struct TripDetailView: View {
    @EnvironmentObject var photoViewModel: PhotoLibraryViewModel
    @EnvironmentObject var tripViewModel: TripViewModel
    
    let trip: Trip
    
    @State private var showEditSheet = false
    @State private var showSlideshow = false
    @State private var selectedPhotoIndex = 0
    @State private var showExportAlert = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(trip.locationName)
                        .font(.title2.bold())
                    
                    Text(trip.formattedDateRange)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 20) {
                        Label("\(trip.photoCount) photos", systemImage: "photo")
                        Label("\(trip.durationDays) days", systemImage: "calendar")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                
                Divider()
                
                // Photo grid
                 LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(Array(trip.photoIDs.enumerated()), id: \.0) { index, photoID in                        if let thumbnail = photoViewModel.thumbnails[photoID] {
                            Button {
                                selectedPhotoIndex = index
                                showSlideshow = true
                            } label: {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fill)
                                    .clipped()
                            }
                            .buttonStyle(.plain)
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .aspectRatio(1, contentMode: .fill)
                                .task {
                                    await photoViewModel.loadThumbnail(for: photoID)
                                }
                        }
                    }
                }
            }
        }
        .navigationTitle(trip.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        tripViewModel.toggleFavorite(trip: trip)
                    } label: {
                        Label(
                            trip.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                            systemImage: trip.isFavorite ? "star.fill" : "star"
                        )
                    }
                    
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit Title", systemImage: "pencil")
                    }
                    
                    Button {
                        selectedPhotoIndex = 0
                        showSlideshow = true
                    } label: {
                        Label("Slideshow", systemImage: "play.circle")
                    }
                    
                    Button {
                        exportToAlbum()
                    } label: {
                        Label("Export to Album", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditTripSheet(trip: trip)
        }
        .fullScreenCover(isPresented: $showSlideshow) {
            SlideshowView(trip: trip, startIndex: selectedPhotoIndex)
        }
        .alert("Export Complete", isPresented: $showExportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Trip photos have been exported to a new album.")
        }
    }
    
    private func exportToAlbum() {
        Task {
            await PhotoLibraryService.shared.createAlbum(name: trip.title, photoIDs: trip.photoIDs)
            showExportAlert = true
        }
    }
}

struct EditTripSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var tripViewModel: TripViewModel
    
    let trip: Trip
    @State private var newTitle: String
    
    init(trip: Trip) {
        self.trip = trip
        _newTitle = State(initialValue: trip.title)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Trip Title", text: $newTitle)
            }
            .navigationTitle("Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        tripViewModel.updateTripTitle(trip: trip, newTitle: newTitle)
                        dismiss()
                    }
                    .disabled(newTitle.isEmpty)
                }
            }
        }
    }
}


import SwiftUI

struct TripDetailView: View {
    @EnvironmentObject var photoViewModel: PhotoLibraryViewModel
    @EnvironmentObject var tripViewModel: TripViewModel
    
    let trip: Trip
    
    @State private var showEditSheet = false
    
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
                    ForEach(trip.photoIDs, id: \.self) { photoID in
                        if let thumbnail = photoViewModel.thumbnails[photoID] {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .aspectRatio(1, contentMode: .fill)
                                .clipped()
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
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditTripSheet(trip: trip)
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


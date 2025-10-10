import SwiftUI
import CoreLocation

struct TripListView: View {
    @EnvironmentObject var photoViewModel: PhotoLibraryViewModel
    @EnvironmentObject var tripViewModel: TripViewModel
    
    @State private var searchText = ""
    @State private var showFavoritesOnly = false
    
    var filteredTrips: [Trip] {
        var result = tripViewModel.trips
        
        if showFavoritesOnly {
            result = result.filter { $0.isFavorite }
        }
        
        if !searchText.isEmpty {
            result = result.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.locationName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if tripViewModel.trips.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredTrips) { trip in
                            NavigationLink(value: trip) {
                                TripCard(trip: trip)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("My Trips")
        .navigationDestination(for: Trip.self) { trip in
            TripDetailView(trip: trip)
        }
        .searchable(text: $searchText, prompt: "Search trips")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showFavoritesOnly.toggle()
                    } label: {
                        Label(
                            showFavoritesOnly ? "Show All" : "Show Favorites",
                            systemImage: showFavoritesOnly ? "star.fill" : "star"
                        )
                    }
                    
                    Button {
                        organizePhotos()
                    } label: {
                        Label("Organize Photos", systemImage: "arrow.triangle.2.circlepath")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .overlay {
            if tripViewModel.isOrganizing {
                ProgressView("Organizing photos...")
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.stack")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Trips Yet")
                .font(.title2.bold())
            
            Text("Tap 'Organize Photos' to automatically create trips from your photos")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                organizePhotos()
            } label: {
                Text("Organize Photos")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    private func organizePhotos() {
        Task {
            let settings = PersistenceService.shared.loadSettings()
            let homeLocation = settings?.homeLocation?.toCLLocation()
            await tripViewModel.organizePhotos(photos: photoViewModel.photos, homeLocation: homeLocation)
        }
    }
}


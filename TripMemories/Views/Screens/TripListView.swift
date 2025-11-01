import SwiftUI
import CoreLocation

struct TripListView: View {
    @EnvironmentObject var photoViewModel: PhotoLibraryViewModel
    @EnvironmentObject var tripViewModel: TripViewModel
    
    @State private var searchText = ""
    @State private var showFavoritesOnly = false
    @State private var sortOption: SortOption = .dateDescending
    @State private var showFilterSheet = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    enum SortOption: String, CaseIterable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case nameAscending = "Name A-Z"
        case nameDescending = "Name Z-A"
        case photoCount = "Most Photos"
        case duration = "Longest Duration"
    }
    
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
        
        // Sort
        switch sortOption {
        case .dateDescending:
            result.sort { $0.startDate > $1.startDate }
        case .dateAscending:
            result.sort { $0.startDate < $1.startDate }
        case .nameAscending:
            result.sort { $0.title < $1.title }
        case .nameDescending:
            result.sort { $0.title > $1.title }
        case .photoCount:
            result.sort { $0.photoCount > $1.photoCount }
        case .duration:
            result.sort { $0.durationDays > $1.durationDays }
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
                HStack(spacing: 16) {
                    Button {
                        showFilterSheet = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    
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
        }
        .overlay {
            if tripViewModel.isOrganizing {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Organizing photos...")
                        .font(.headline)
                    if !PhotoLibraryService.shared.loadingProgress.isEmpty {
                        Text(PhotoLibraryService.shared.loadingProgress)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("This may take a moment")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(24)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .alert("Photo Library Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheet(sortOption: $sortOption, showFavoritesOnly: $showFavoritesOnly)
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
        print("🔴 Organize button clicked!")
        print("📸 Photos available: \(photoViewModel.photos.count)")
        
        Task {
            // Check for loading errors from PhotoLibraryService
            if let error = PhotoLibraryService.shared.loadingError {
                print("⚠️ Loading error detected: \(error)")
                await MainActor.run {
                    errorMessage = error
                    showErrorAlert = true
                }
                return
            }
            
            // Clear any previous loading error
            PhotoLibraryService.shared.loadingError = nil
            
            let settings = PersistenceService.shared.loadSettings()
            let homeLocation = settings?.homeLocation?.toCLLocation()
            print("🏠 Home location: \(homeLocation?.coordinate.latitude ?? 0), \(homeLocation?.coordinate.longitude ?? 0)")
            print("📤 Calling tripViewModel.organizePhotos...")
            
            await tripViewModel.organizePhotos(photos: photoViewModel.photos, homeLocation: homeLocation)
            
            print("📥 Returned from tripViewModel.organizePhotos")
        }
    }
}

struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var sortOption: TripListView.SortOption
    @Binding var showFavoritesOnly: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Sort By") {
                    ForEach(TripListView.SortOption.allCases, id: \.self) { option in
                        Button {
                            sortOption = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("Filter") {
                    Toggle("Favorites Only", isOn: $showFavoritesOnly)
                }
            }
            .navigationTitle("Sort & Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}


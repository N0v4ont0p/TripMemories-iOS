import SwiftUI

struct TripListView: View {
    @EnvironmentObject var photoViewModel: PhotoLibraryViewModel
    @EnvironmentObject var tripViewModel: TripViewModel
    
    @State private var showOrganizeConfirmation = false
    @State private var searchText = ""
    @State private var selectedCategory: TripCategory?
    @State private var showFavoritesOnly = false
    @State private var sortOption: SortOption = .dateDescending
    @State private var showSortMenu = false
    
    private let spacing: CGFloat = 24
    private let minCardWidth: CGFloat = 350
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    // Search and filters
                    if !tripViewModel.trips.isEmpty {
                        searchAndFilterSection
                    }
                    
                    // Content
                    if tripViewModel.isOrganizing {
                        organizingView
                    } else if tripViewModel.trips.isEmpty {
                        emptyStateView
                    } else if filteredTrips.isEmpty {
                        noResultsView
                    } else {
                        tripsGridView(width: geometry.size.width)
                    }
                }
            }
            .navigationTitle("My Trips")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if !tripViewModel.trips.isEmpty {
                        Button {
                            showSortMenu.toggle()
                        } label: {
                            Label("Sort", systemImage: "arrow.up.arrow.down")
                        }
                        .popover(isPresented: $showSortMenu) {
                            sortMenu
                        }
                        
                        Button {
                            showOrganizeConfirmation = true
                        } label: {
                            Label("Reorganize", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                }
            }
            .alert("Reorganize Trips?", isPresented: $showOrganizeConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reorganize", role: .destructive) {
                    Task {
                        let settings = PersistenceService.shared.loadSettings()
                        await tripViewModel.organizeTrips(photos: photoViewModel.photos, settings: settings)
                    }
                }
            } message: {
                Text("This will re-analyze all your photos and create new trip albums.")
            }
        }
    }
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search trips...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, spacing)
            
            // Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Favorites filter
                    FilterChip(
                        title: "Favorites",
                        icon: "star.fill",
                        isSelected: showFavoritesOnly
                    ) {
                        withAnimation {
                            showFavoritesOnly.toggle()
                        }
                    }
                    
                    // Category filters
                    ForEach(TripCategory.allCases, id: \.self) { category in
                        FilterChip(
                            title: category.rawValue,
                            icon: category.icon,
                            isSelected: selectedCategory == category
                        ) {
                            withAnimation {
                                if selectedCategory == category {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, spacing)
            }
        }
    }
    
    private var sortMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button {
                    sortOption = option
                    showSortMenu = false
                } label: {
                    HStack {
                        Text(option.title)
                        Spacer()
                        if sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                    .padding()
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                if option != SortOption.allCases.last {
                    Divider()
                }
            }
        }
        .frame(width: 200)
    }
    
    private func tripsGridView(width: CGFloat) -> some View {
        let columns = calculateColumns(for: width)
        
        return LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(Array(filteredTrips.enumerated()), id: \.element.id) { index, trip in
                NavigationLink(value: trip) {
                    EnhancedTripCard(
                        trip: trip,
                        thumbnail: tripViewModel.thumbnails[trip.coverPhotoID ?? ""],
                        onToggleFavorite: {
                            tripViewModel.toggleFavorite(trip: trip)
                        }
                    )
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05), value: filteredTrips.count)
            }
        }
        .padding(spacing)
    }
    
    private var organizingView: some View {
        VStack(spacing: 24) {
            ProgressView(value: tripViewModel.organizingProgress)
                .scaleEffect(1.2)
                .frame(width: 200)
            
            VStack(spacing: 8) {
                Text("Organizing your trips...")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("This may take a minute")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            Image(systemName: "photo.stack")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                Text("No Trips Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Organize your photos to create beautiful trip albums")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                Task {
                    let settings = PersistenceService.shared.loadSettings()
                    await tripViewModel.organizeTrips(photos: photoViewModel.photos, settings: settings)
                }
            } label: {
                Label("Organize Photos", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private var noResultsView: some View {
        VStack(spacing: 24) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("No Results")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Try adjusting your search or filters")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            Button("Clear Filters") {
                withAnimation {
                    searchText = ""
                    selectedCategory = nil
                    showFavoritesOnly = false
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private var filteredTrips: [Trip] {
        var trips = tripViewModel.trips
        
        // Apply search
        if !searchText.isEmpty {
            trips = trips.filter {
                $0.displayTitle.localizedCaseInsensitiveContains(searchText) ||
                $0.locationName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            trips = trips.filter { $0.category == category }
        }
        
        // Apply favorites filter
        if showFavoritesOnly {
            trips = trips.filter { $0.isFavorite }
        }
        
        // Apply sorting
        return sortOption.sort(trips)
    }
    
    private func calculateColumns(for width: CGFloat) -> [GridItem] {
        let availableWidth = width - (spacing * 2)
        let columnCount = max(1, Int(availableWidth / (minCardWidth + spacing)))
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                    LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing) :
                    LinearGradient(colors: [Color.gray.opacity(0.2)], startPoint: .leading, endPoint: .trailing),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sort Options

enum SortOption: CaseIterable {
    case dateDescending
    case dateAscending
    case nameAscending
    case nameDescending
    case photosDescending
    case durationDescending
    
    var title: String {
        switch self {
        case .dateDescending: return "Newest First"
        case .dateAscending: return "Oldest First"
        case .nameAscending: return "Name (A-Z)"
        case .nameDescending: return "Name (Z-A)"
        case .photosDescending: return "Most Photos"
        case .durationDescending: return "Longest Duration"
        }
    }
    
    func sort(_ trips: [Trip]) -> [Trip] {
        switch self {
        case .dateDescending:
            return trips.sorted { $0.startDate > $1.startDate }
        case .dateAscending:
            return trips.sorted { $0.startDate < $1.startDate }
        case .nameAscending:
            return trips.sorted { $0.displayTitle < $1.displayTitle }
        case .nameDescending:
            return trips.sorted { $0.displayTitle > $1.displayTitle }
        case .photosDescending:
            return trips.sorted { $0.photoCount > $1.photoCount }
        case .durationDescending:
            return trips.sorted { $0.durationDays > $1.durationDays }
        }
    }
}

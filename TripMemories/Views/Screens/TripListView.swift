import SwiftUI

struct TripListView: View {
    @EnvironmentObject var photoViewModel: PhotoLibraryViewModel
    @EnvironmentObject var tripViewModel: TripViewModel
    
    @State private var showOrganizeConfirmation = false
    
    private let spacing: CGFloat = 24
    private let minCardWidth: CGFloat = 350
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                if tripViewModel.isOrganizing {
                    organizingView
                } else if tripViewModel.trips.isEmpty {
                    emptyStateView
                } else {
                    tripsGridView(width: geometry.size.width)
                }
            }
            .navigationTitle("My Trips")
            .toolbar {
                if !tripViewModel.trips.isEmpty {
                    Button {
                        showOrganizeConfirmation = true
                    } label: {
                        Label("Reorganize", systemImage: "arrow.triangle.2.circlepath")
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
    
    private func tripsGridView(width: CGFloat) -> some View {
        let columns = calculateColumns(for: width)
        
        return LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(Array(tripViewModel.trips.enumerated()), id: \.element.id) { index, trip in
                NavigationLink(value: trip) {
                    TripCard(trip: trip, thumbnail: tripViewModel.thumbnails[trip.coverPhotoID ?? ""])
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05), value: tripViewModel.trips.count)
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
    
    private func calculateColumns(for width: CGFloat) -> [GridItem] {
        let availableWidth = width - (spacing * 2)
        let columnCount = max(1, Int(availableWidth / (minCardWidth + spacing)))
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }
}

import SwiftUI

struct TimelineView: View {
    @EnvironmentObject var tripViewModel: TripViewModel
    @EnvironmentObject var photoViewModel: PhotoLibraryViewModel
    
    private var tripsByYear: [(year: String, trips: [Trip])] {
        let grouped = Dictionary(grouping: tripViewModel.trips) { trip in
            let year = Calendar.current.component(.year, from: trip.startDate)
            return String(year)
        }
        
        return grouped.map { (year: $0.key, trips: $0.value.sorted { $0.startDate > $1.startDate }) }
            .sorted { $0.year > $1.year }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24, pinnedViews: [.sectionHeaders]) {
                    ForEach(tripsByYear, id: \.year) { yearGroup in
                        Section {
                            ForEach(yearGroup.trips) { trip in
                                NavigationLink(value: trip) {
                                    TimelineTripRow(trip: trip)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            YearHeader(year: yearGroup.year, count: yearGroup.trips.count)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Timeline")
            .navigationDestination(for: Trip.self) { trip in
                TripDetailView(trip: trip)
            }
        }
    }
}

struct YearHeader: View {
    let year: String
    let count: Int
    
    var body: some View {
        HStack {
            Text(year)
                .font(.title.bold())
            
            Spacer()
            
            Text("\(count) trip\(count == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(.ultraThinMaterial)
    }
}

struct TimelineTripRow: View {
    @EnvironmentObject var photoViewModel: PhotoLibraryViewModel
    let trip: Trip
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail
            if let firstPhotoID = trip.photoIDs.first,
               let thumbnail = photoViewModel.thumbnails[firstPhotoID] {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.title)
                    .font(.headline)
                
                Text(trip.locationName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    Label("\(trip.photoCount)", systemImage: "photo")
                    Label("\(trip.durationDays)d", systemImage: "calendar")
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            if trip.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
        .task {
            if let firstPhotoID = trip.photoIDs.first {
                await photoViewModel.loadThumbnail(for: firstPhotoID)
            }
        }
    }
}


import SwiftUI

struct TimelineView: View {
    @EnvironmentObject var tripViewModel: TripViewModel
    
    @State private var selectedYear: Int?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Year selector
                if !availableYears.isEmpty {
                    yearSelector
                }
                
                // Timeline
                if tripViewModel.trips.isEmpty {
                    emptyState
                } else {
                    ForEach(groupedTrips.keys.sorted(by: >), id: \.self) { year in
                        yearSection(year: year, trips: groupedTrips[year] ?? [])
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Timeline")
        .onAppear {
            if selectedYear == nil && !availableYears.isEmpty {
                selectedYear = availableYears.first
            }
        }
    }
    
    private var yearSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(availableYears, id: \.self) { year in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedYear = year
                            scrollToYear(year)
                        }
                    } label: {
                        Text(String(year))
                            .font(.headline)
                            .foregroundStyle(selectedYear == year ? .white : .primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                selectedYear == year ?
                                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [Color.gray.opacity(0.2)], startPoint: .leading, endPoint: .trailing),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private func yearSection(year: Int, trips: [Trip]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Year header
            HStack {
                Text(String(year))
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(trips.count) trip\(trips.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
            
            // Trips for this year
            ForEach(trips) { trip in
                NavigationLink(value: trip) {
                    TimelineTripCard(trip: trip, thumbnail: tripViewModel.thumbnails[trip.coverPhotoID ?? ""])
                }
                .buttonStyle(.plain)
            }
        }
        .id(year)
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("No Trips Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Organize your photos to see your travel timeline")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private var availableYears: [Int] {
        let years = Set(tripViewModel.trips.map { $0.year })
        return Array(years).sorted(by: >)
    }
    
    private var groupedTrips: [Int: [Trip]] {
        Dictionary(grouping: tripViewModel.trips) { $0.year }
    }
    
    private func scrollToYear(_ year: Int) {
        // Scroll animation handled by SwiftUI
    }
}

struct TimelineTripCard: View {
    let trip: Trip
    let thumbnail: PlatformImage?
    
    var body: some View {
        HStack(spacing: 16) {
            // Timeline indicator
            VStack {
                Circle()
                    .fill(Color(trip.category.color))
                    .frame(width: 16, height: 16)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2)
            }
            
            // Trip card
            HStack(spacing: 16) {
                // Thumbnail
                if let thumbnail = thumbnail {
                    Image(platformImage: thumbnail)
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
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(trip.displayTitle)
                            .font(.headline)
                            .lineLimit(1)
                        
                        if trip.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                    }
                    
                    Text(trip.formattedDateRange)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        Label("\(trip.photoCount)", systemImage: "photo")
                        Label("\(trip.durationDays)d", systemImage: "calendar")
                        Label(trip.category.rawValue, systemImage: trip.category.icon)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

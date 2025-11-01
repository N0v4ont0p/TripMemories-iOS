import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var tripViewModel: TripViewModel
    
    private var totalTrips: Int {
        tripViewModel.trips.count
    }
    
    private var totalPhotos: Int {
        tripViewModel.trips.reduce(0) { $0 + $1.photoCount }
    }
    
    private var totalDays: Int {
        tripViewModel.trips.reduce(0) { $0 + $1.durationDays }
    }
    
    private var uniqueLocations: Int {
        Set(tripViewModel.trips.map { $0.locationName }).count
    }
    
    private var tripsByYear: [(year: String, count: Int)] {
        let grouped = Dictionary(grouping: tripViewModel.trips) { trip in
            let year = Calendar.current.component(.year, from: trip.startDate)
            return String(year)
        }
        
        return grouped.map { (year: $0.key, count: $0.value.count) }
            .sorted { $0.year > $1.year }
    }
    
    private var topDestinations: [(location: String, count: Int)] {
        let grouped = Dictionary(grouping: tripViewModel.trips) { $0.locationName }
        return grouped.map { (location: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0 }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Overview Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(title: "Trips", value: "\(totalTrips)", icon: "airplane", color: .blue)
                        StatCard(title: "Photos", value: "\(totalPhotos)", icon: "photo.stack", color: .green)
                        StatCard(title: "Days", value: "\(totalDays)", icon: "calendar", color: .orange)
                        StatCard(title: "Places", value: "\(uniqueLocations)", icon: "mappin.circle", color: .purple)
                    }
                    
                    // Trips by Year
                    if !tripsByYear.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Trips by Year")
                                .font(.title2.bold())
                            
                            ForEach(tripsByYear, id: \.year) { item in
                                YearBar(year: item.year, count: item.count, maxCount: tripsByYear.map { $0.count }.max() ?? 1)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Top Destinations
                    if !topDestinations.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Top Destinations")
                                .font(.title2.bold())
                            
                            ForEach(Array(topDestinations.enumerated()), id: \.offset) { index, item in
                                DestinationRow(rank: index + 1, location: item.location, count: item.count)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
            .navigationTitle("Statistics")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(color)
            
            Text(value)
                .font(.title.bold())
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct YearBar: View {
    let year: String
    let count: Int
    let maxCount: Int
    
    private var percentage: Double {
        Double(count) / Double(maxCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(year)
                    .font(.subheadline.bold())
                
                Spacer()
                
                Text("\(count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * percentage)
                }
            }
            .frame(height: 8)
        }
    }
}

struct DestinationRow: View {
    let rank: Int
    let location: String
    let count: Int
    
    private var medalEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)."
        }
    }
    
    var body: some View {
        HStack {
            Text(medalEmoji)
                .font(.title3)
                .frame(width: 40)
            
            Text(location)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(count) trip\(count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}


import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var tripViewModel: TripViewModel
    @EnvironmentObject var photoViewModel: PhotoLibraryViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Overview cards
                overviewSection
                
                // Travel by year
                yearlyTravelSection
                
                // Categories breakdown
                categoriesSection
                
                // Top destinations
                destinationsSection
                
                // Photo stats
                photoStatsSection
            }
            .padding()
        }
        .navigationTitle("Statistics")
    }
    
    private var overviewSection: some View {
        VStack(spacing: 16) {
            Text("Travel Overview")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(
                    title: "Total Trips",
                    value: "\(tripViewModel.trips.count)",
                    icon: "airplane",
                    color: .blue
                )
                
                StatCard(
                    title: "Countries",
                    value: "\(uniqueCountries)",
                    icon: "globe",
                    color: .green
                )
                
                StatCard(
                    title: "Total Days",
                    value: "\(totalDays)",
                    icon: "calendar",
                    color: .orange
                )
                
                StatCard(
                    title: "Photos",
                    value: "\(totalPhotos)",
                    icon: "photo.stack",
                    color: .purple
                )
            }
        }
    }
    
    private var yearlyTravelSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Travel by Year")
                .font(.title3)
                .fontWeight(.semibold)
            
            ForEach(yearlyStats.sorted(by: { $0.key > $1.key }), id: \.key) { year, count in
                HStack {
                    Text(String(year))
                        .font(.headline)
                        .frame(width: 60, alignment: .leading)
                    
                    GeometryReader { geometry in
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: barWidth(for: count, in: geometry.size.width))
                            
                            Text("\(count) trip\(count == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(height: 30)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trip Categories")
                .font(.title3)
                .fontWeight(.semibold)
            
            ForEach(TripCategory.allCases, id: \.self) { category in
                let count = tripsByCategory[category] ?? 0
                if count > 0 {
                    HStack {
                        Label(category.rawValue, systemImage: category.icon)
                            .font(.subheadline)
                            .frame(width: 140, alignment: .leading)
                        
                        GeometryReader { geometry in
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(category.color))
                                    .frame(width: categoryBarWidth(for: count, in: geometry.size.width))
                                
                                Text("\(count)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(height: 24)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var destinationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Destinations")
                .font(.title3)
                .fontWeight(.semibold)
            
            ForEach(Array(topDestinations.prefix(5)), id: \.key) { destination, count in
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.red)
                    
                    Text(destination)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(count) trip\(count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var photoStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Photo Statistics")
                .font(.title3)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Average per Trip")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(averagePhotosPerTrip)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Longest Trip")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(longestTripDays) days")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            if let mostPhotosTrip = tripWithMostPhotos {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Most Photos")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(mostPhotosTrip.displayTitle)
                        .font(.headline)
                    Text("\(mostPhotosTrip.photoCount) photos")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.purple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Computed Properties
    
    private var uniqueCountries: Int {
        Set(tripViewModel.trips.map { $0.locationName }).count
    }
    
    private var totalDays: Int {
        tripViewModel.trips.reduce(0) { $0 + $1.durationDays }
    }
    
    private var totalPhotos: Int {
        tripViewModel.trips.reduce(0) { $0 + $1.photoCount }
    }
    
    private var yearlyStats: [Int: Int] {
        Dictionary(grouping: tripViewModel.trips) { $0.year }
            .mapValues { $0.count }
    }
    
    private var tripsByCategory: [TripCategory: Int] {
        Dictionary(grouping: tripViewModel.trips) { $0.category }
            .mapValues { $0.count }
    }
    
    private var topDestinations: [(key: String, value: Int)] {
        let destinations = Dictionary(grouping: tripViewModel.trips) { $0.locationName }
            .mapValues { $0.count }
        return destinations.sorted { $0.value > $1.value }
    }
    
    private var averagePhotosPerTrip: Int {
        guard !tripViewModel.trips.isEmpty else { return 0 }
        return totalPhotos / tripViewModel.trips.count
    }
    
    private var longestTripDays: Int {
        tripViewModel.trips.map { $0.durationDays }.max() ?? 0
    }
    
    private var tripWithMostPhotos: Trip? {
        tripViewModel.trips.max { $0.photoCount < $1.photoCount }
    }
    
    private func barWidth(for count: Int, in maxWidth: CGFloat) -> CGFloat {
        guard let maxCount = yearlyStats.values.max(), maxCount > 0 else { return 0 }
        return (CGFloat(count) / CGFloat(maxCount)) * (maxWidth - 100)
    }
    
    private func categoryBarWidth(for count: Int, in maxWidth: CGFloat) -> CGFloat {
        guard let maxCount = tripsByCategory.values.max(), maxCount > 0 else { return 0 }
        return (CGFloat(count) / CGFloat(maxCount)) * (maxWidth - 50)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

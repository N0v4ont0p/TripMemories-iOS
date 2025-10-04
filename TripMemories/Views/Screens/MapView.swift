import SwiftUI
import MapKit

struct MapView: View {
    let trips: [Trip]
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 100, longitudeDelta: 100)
    )
    
    var body: some View {
        ZStack {
            if !tripLocations.isEmpty {
                Map(coordinateRegion: $region, annotationItems: tripLocations) { location in
                    MapAnnotation(coordinate: location.coordinate) {
                        VStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundStyle(.red)
                            
                            Text(location.name)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(radius: 2)
                        }
                    }
                }
                .ignoresSafeArea()
                .onAppear {
                    updateRegion()
                }
            } else {
                emptyStateView
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "map")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("No Trip Locations")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Organize your photos to see trips on the map")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
    
    private var tripLocations: [TripLocation] {
        trips.compactMap { trip in
            guard let centroid = trip.centroid,
                  isValidCoordinate(latitude: centroid.latitude, longitude: centroid.longitude) else {
                return nil
            }
            
            return TripLocation(
                id: trip.id,
                name: trip.locationName,
                coordinate: CLLocationCoordinate2D(
                    latitude: centroid.latitude,
                    longitude: centroid.longitude
                )
            )
        }
    }
    
    private func isValidCoordinate(latitude: Double, longitude: Double) -> Bool {
        return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180
    }
    
    private func updateRegion() {
        guard !tripLocations.isEmpty else { return }
        
        let coordinates = tripLocations.map { $0.coordinate }
        
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        // Calculate span with safety limits
        let latDelta = max(0.5, min(170, (maxLat - minLat) * 1.5))
        let lonDelta = max(0.5, min(350, (maxLon - minLon) * 1.5))
        
        let span = MKCoordinateSpan(
            latitudeDelta: latDelta,
            longitudeDelta: lonDelta
        )
        
        region = MKCoordinateRegion(center: center, span: span)
    }
}

struct TripLocation: Identifiable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
}

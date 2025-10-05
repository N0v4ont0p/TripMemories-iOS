import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var tripViewModel: TripViewModel
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 100, longitudeDelta: 100)
    )
    @State private var tripLocations: [TripLocation] = []
    
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
            } else {
                emptyStateView
            }
        }
        .onAppear {
            updateTripLocations()
        }
        .onChange(of: tripViewModel.trips.count) { _ in
            updateTripLocations()
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
    
    private func updateTripLocations() {
        // Convert trips to locations
        let locations = tripViewModel.trips.compactMap { trip -> TripLocation? in
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
        
        tripLocations = locations
        updateRegion(for: locations)
    }
    
    private func isValidCoordinate(latitude: Double, longitude: Double) -> Bool {
        return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180
    }
    
    private func updateRegion(for locations: [TripLocation]) {
        guard !locations.isEmpty else {
            // Reset to default world view if no trips
            withAnimation(.easeInOut(duration: 0.5)) {
                region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
                    span: MKCoordinateSpan(latitudeDelta: 100, longitudeDelta: 100)
                )
            }
            return
        }
        
        let coordinates = locations.map { $0.coordinate }
        
        guard let minLat = coordinates.map({ $0.latitude }).min(),
              let maxLat = coordinates.map({ $0.latitude }).max(),
              let minLon = coordinates.map({ $0.longitude }).min(),
              let maxLon = coordinates.map({ $0.longitude }).max() else {
            return
        }
        
        // Validate coordinates
        guard minLat >= -90, maxLat <= 90, minLon >= -180, maxLon <= 180 else {
            print("⚠️ Invalid coordinates detected, skipping region update")
            return
        }
        
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
        
        // Animate region change
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(center: center, span: span)
        }
    }
}

struct TripLocation: Identifiable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
}

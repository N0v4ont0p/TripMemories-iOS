import SwiftUI
import CoreLocation

struct OnboardingView: View {
    @Binding var isPresented: Bool
    
    @State private var homeCity: String = ""
    @State private var searchResults: [CLPlacemark] = []
    @State private var selectedLocation: CLLocation?
    @State private var isSearching = false
    
    private let geocoder = CLGeocoder()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                    
                    Text("Welcome to TripMemories")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("Let's organize your travel photos")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                }
                
                // Search box
                VStack(alignment: .leading, spacing: 16) {
                    Text("What's your home city?")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    TextField("Enter your city", text: $homeCity)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                        .onChange(of: homeCity) { _, newValue in
                            searchCity(newValue)
                        }
                    
                    if isSearching {
                        ProgressView()
                            .tint(.white)
                    }
                    
                    if !searchResults.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(searchResults, id: \.self) { placemark in
                                Button {
                                    selectLocation(placemark)
                                } label: {
                                    HStack {
                                        Image(systemName: "mappin.circle.fill")
                                        VStack(alignment: .leading) {
                                            Text(placemark.locality ?? "Unknown")
                                                .fontWeight(.semibold)
                                            Text(placemark.country ?? "")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                    .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                
                // Continue button
                Button {
                    completeOnboarding()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedLocation != nil ? Color.green : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(selectedLocation == nil)
                
                Spacer()
            }
            .padding(40)
        }
    }
    
    private func searchCity(_ query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        geocoder.geocodeAddressString(query) { placemarks, error in
            isSearching = false
            
            if let placemarks = placemarks {
                searchResults = Array(placemarks.prefix(5))
            } else {
                searchResults = []
            }
        }
    }
    
    private func selectLocation(_ placemark: CLPlacemark) {
        selectedLocation = placemark.location
        homeCity = placemark.locality ?? placemark.administrativeArea ?? ""
        searchResults = []
    }
    
    private func completeOnboarding() {
        guard let location = selectedLocation else { return }
        
        var settings = PersistenceService.shared.loadSettings() ?? UserSettings()
        settings.homeCity = homeCity
        settings.homeLocation = CodableLocation(location: location)
        settings.homeCountry = searchResults.first?.country
        settings.hasCompletedOnboarding = true
        
        try? PersistenceService.shared.saveSettings(settings)
        
        isPresented = false
    }
}

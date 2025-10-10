import SwiftUI
import CoreLocation

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var locationManager = CLLocationManager()
    @State private var currentStep = 0
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "photo.stack.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            Text("Welcome to TripMemories")
                .font(.largeTitle.bold())
            
            Text("Automatically organize your photos into trips")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button {
                complete()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
    
    private func complete() {
        locationManager.requestWhenInUseAuthorization()
        
        var settings = UserSettings()
        settings.hasCompletedOnboarding = true
        
        if let location = locationManager.location {
            settings.homeLocation = UserSettings.Location(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
        
        try? PersistenceService.shared.saveSettings(settings)
        isPresented = false
    }
}


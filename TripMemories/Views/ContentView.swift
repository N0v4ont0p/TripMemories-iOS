import SwiftUI

struct ContentView: View {
    @EnvironmentObject var photoViewModel: PhotoLibraryViewModel
    @EnvironmentObject var tripViewModel: TripViewModel
    
    @State private var showOnboarding = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Trips Tab
            NavigationStack {
                TripListView()
                    .navigationDestination(for: Trip.self) { trip in
                        TripDetailView(trip: trip)
                    }
            }
            .tabItem {
                Label("Trips", systemImage: "photo.stack.fill")
            }
            .tag(0)
            
            // Timeline Tab
            NavigationStack {
                TimelineView()
            }
            .tabItem {
                Label("Timeline", systemImage: "calendar")
            }
            .tag(1)
            
            // Statistics Tab
            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar.fill")
            }
            .tag(2)
        }
        .onAppear {
            checkOnboarding()
            requestPhotoAccess()
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
                .interactiveDismissDisabled()
        }
    }
    
    private func checkOnboarding() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let settings = PersistenceService.shared.loadSettings()
            if settings == nil || !settings!.hasCompletedOnboarding {
                showOnboarding = true
            }
        }
    }
    
    private func requestPhotoAccess() {
        Task {
            await photoViewModel.requestAuthorization()
            if photoViewModel.authorizationStatus == .authorized {
                await photoViewModel.fetchPhotos()
            }
        }
    }
}

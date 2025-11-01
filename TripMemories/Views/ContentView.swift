import SwiftUI

struct ContentView: View {
    @EnvironmentObject var photoViewModel: PhotoLibraryViewModel
    @EnvironmentObject var tripViewModel: TripViewModel
    
    @State private var showOnboarding = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TripListView()
            }
            .tabItem {
                Label("Trips", systemImage: "suitcase")
            }
            .tag(0)
            
            NavigationStack {
                TimelineView()
            }
            .tabItem {
                Label("Timeline", systemImage: "clock")
            }
            .tag(1)
            
            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
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


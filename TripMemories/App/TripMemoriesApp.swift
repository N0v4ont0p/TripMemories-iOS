import SwiftUI

@main
struct TripMemoriesApp: App {
    @StateObject private var photoViewModel = PhotoLibraryViewModel()
    @StateObject private var tripViewModel = TripViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(photoViewModel)
                .environmentObject(tripViewModel)
        }
    }
}


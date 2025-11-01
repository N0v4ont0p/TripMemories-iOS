import SwiftUI
import Photos

struct SlideshowView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var photoViewModel: PhotoLibraryViewModel
    
    let trip: Trip
    @State private var currentIndex: Int
    @State private var fullImages: [String: UIImage] = [:]
    @State private var isLoading = false
    
    init(trip: Trip, startIndex: Int = 0) {
        self.trip = trip
        _currentIndex = State(initialValue: startIndex)
    }
    
    private var currentPhotoID: String? {
        guard currentIndex < trip.photoIDs.count else { return nil }
        return trip.photoIDs[currentIndex]
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $currentIndex) {
                ForEach(Array(trip.photoIDs.enumerated()), id: \.offset) { index, photoID in
                    ZStack {
                        if let fullImage = fullImages[photoID] {
                            Image(uiImage: fullImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .tag(index)
                        } else if let thumbnail = photoViewModel.thumbnails[photoID] {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .blur(radius: 2)
                                .tag(index)
                                .overlay {
                                    ProgressView()
                                        .tint(.white)
                                }
                        } else {
                            ProgressView()
                                .tint(.white)
                                .tag(index)
                        }
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: currentIndex) { newIndex in
                loadFullImage(at: newIndex)
            }
            
            // Controls overlay
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding()
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    
                    Spacer()
                    
                    Text("\(currentIndex + 1) / \(trip.photoIDs.count)")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .padding()
                
                Spacer()
            }
        }
        .statusBar(hidden: true)
        .task {
            loadFullImage(at: currentIndex)
        }
    }
    
    private func loadFullImage(at index: Int) {
        guard index < trip.photoIDs.count else { return }
        let photoID = trip.photoIDs[index]
        
        if fullImages[photoID] != nil { return }
        
        Task {
            if let image = await PhotoLibraryService.shared.loadFullImage(for: photoID) {
                fullImages[photoID] = image
            }
        }
    }
}


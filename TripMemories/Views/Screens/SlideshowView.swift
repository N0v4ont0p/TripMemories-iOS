import SwiftUI

struct SlideshowView: View {
    let trip: Trip
    let photos: [Photo]
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripViewModel: TripViewModel
    
    @State private var currentIndex = 0
    @State private var isPlaying = false
    @State private var timer: Timer?
    @State private var showControls = true
    @State private var hideControlsTask: Task<Void, Never>?
    
    private let slideDuration: TimeInterval = 3.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Photo display
            TabView(selection: $currentIndex) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    if let thumbnail = tripViewModel.thumbnails[photo.id] {
                        Image(platformImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .tag(index)
                    } else {
                        ProgressView()
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            // Controls overlay
            if showControls {
                VStack {
                    // Top bar
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .shadow(radius: 4)
                        }
                        
                        Spacer()
                        
                        Text("\(currentIndex + 1) / \(photos.count)")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Bottom controls
                    VStack(spacing: 20) {
                        // Progress bar
                        ProgressView(value: Double(currentIndex + 1), total: Double(photos.count))
                            .tint(.white)
                            .padding(.horizontal)
                        
                        // Playback controls
                        HStack(spacing: 40) {
                            Button {
                                previousPhoto()
                            } label: {
                                Image(systemName: "backward.fill")
                                    .font(.title)
                                    .foregroundStyle(.white)
                            }
                            .disabled(currentIndex == 0)
                            
                            Button {
                                togglePlayback()
                            } label: {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .font(.title)
                                    .foregroundStyle(.white)
                            }
                            
                            Button {
                                nextPhoto()
                            } label: {
                                Image(systemName: "forward.fill")
                                    .font(.title)
                                    .foregroundStyle(.white)
                            }
                            .disabled(currentIndex == photos.count - 1)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    }
                    .padding()
                }
                .transition(.opacity)
            }
        }
        .statusBar(hidden: !showControls)
        .onTapGesture {
            withAnimation {
                showControls.toggle()
            }
            scheduleHideControls()
        }
        .onAppear {
            scheduleHideControls()
        }
        .onDisappear {
            stopPlayback()
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }
    
    private func startPlayback() {
        isPlaying = true
        timer = Timer.scheduledTimer(withTimeInterval: slideDuration, repeats: true) { _ in
            nextPhoto()
        }
    }
    
    private func stopPlayback() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }
    
    private func nextPhoto() {
        if currentIndex < photos.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        } else {
            stopPlayback()
        }
    }
    
    private func previousPhoto() {
        if currentIndex > 0 {
            withAnimation {
                currentIndex -= 1
            }
        }
    }
    
    private func scheduleHideControls() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            if !Task.isCancelled {
                withAnimation {
                    showControls = false
                }
            }
        }
    }
}

#if os(macOS)
import AppKit
typealias PlatformImage = NSImage
#else
import UIKit
typealias PlatformImage = UIImage
#endif

extension Image {
    init(platformImage: PlatformImage) {
        #if os(macOS)
        self.init(nsImage: platformImage)
        #else
        self.init(uiImage: platformImage)
        #endif
    }
}

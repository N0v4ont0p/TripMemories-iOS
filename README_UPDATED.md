# TripMemories - iOS Photo Trip Organizer 📸✈️

## What's New in This Version (v1.1.0)

This updated version includes critical fixes that resolve all major issues with the app:

**Fixed Issues:**
- ✅ AttributeGraph cycle causing crashes when switching tabs
- ✅ Map view crashes and instability
- ✅ Missing trip detection (UK/US trips now properly detected)
- ✅ Slow iCloud photo loading and timeouts
- ✅ Poor location naming (now shows city names for better clarity)

---

## Installation Instructions

### Step 1: Extract the Project
Extract the `TripMemories-iOS-FIXED.tar.gz` file to your desired location.

### Step 2: Open in Xcode
1. Open Xcode on your Mac
2. Navigate to `File > Open`
3. Select the `TripMemories.xcodeproj` file
4. Wait for Xcode to index the project

### Step 3: Configure Signing
1. Select the project in the navigator (blue icon at the top)
2. Select the "TripMemories" target
3. Go to "Signing & Capabilities" tab
4. Select your Apple Developer team
5. Xcode will automatically manage the bundle identifier

### Step 4: Build and Run
1. Connect your iPhone or iPad via USB
2. Select your device from the device menu in Xcode
3. Click the "Run" button (▶️) or press `Cmd+R`
4. The app will build and install on your device

### Step 5: Grant Permissions
When you first launch the app:
1. Complete the onboarding by setting your home location
2. Grant photo library access when prompted
3. Tap "Organize Photos" to create your first trips

---

## Features

**Smart Trip Detection** - Automatically groups photos into trips based on location and time, with improved accuracy for detecting trips of all sizes.

**Beautiful UI** - Modern, clean interface with smooth animations and intuitive navigation.

**Interactive Map** - View all your trips on a world map with location pins and labels.

**iCloud Support** - Seamlessly loads photos from iCloud with optimized performance and progress tracking.

**Trip Details** - Browse photos from each trip in a beautiful grid layout with full-screen viewing.

---

## How It Works

The app uses a sophisticated clustering algorithm to organize your photos into meaningful trips:

**Location Analysis** - Photos taken more than 30km from your home location are considered potential trip photos.

**Time Grouping** - Photos taken within 4 days of each other and within 150km are grouped together.

**Smart Merging** - Nearby clusters (within 200km) taken within 30 days are intelligently merged into single trips.

**Location Naming** - Uses reverse geocoding to provide descriptive location names. For domestic trips, it shows the city name. For international trips, it shows the country, or "City, Country Code" for large countries like the USA and UK.

---

## Technical Details

**Architecture:** MVVM (Model-View-ViewModel) pattern with SwiftUI

**Photo Access:** PhotoKit framework for accessing the photo library

**Location Services:** Core Location for geocoding and distance calculations

**Map Integration:** MapKit for displaying trip locations

**Data Persistence:** JSON-based caching for trips and geocoding results

**Concurrency:** Swift async/await for responsive performance

---

## Performance Optimizations

**Batch Processing** - Photos are loaded in batches of 20 to balance speed and memory usage.

**Smart Caching** - Geocoding results are cached to avoid redundant API calls.

**Progressive Loading** - Thumbnails load progressively with visible progress tracking.

**Timeout Handling** - 10-second timeout per photo prevents the app from hanging on slow iCloud downloads.

**Memory Management** - Weak references and proper cleanup prevent memory leaks.

---

## Troubleshooting

**Issue: No trips are detected**
- Make sure you've set your home location correctly during onboarding
- Verify that your photos have location data (check in the Photos app)
- Try adjusting your home location and reorganizing

**Issue: Some photos are missing from trips**
- Photos without location data are automatically excluded
- Check if the photos have GPS coordinates in the Photos app
- iCloud photos may take time to download initially

**Issue: Map is not showing trip locations**
- Ensure you have organized your photos first
- Check that trips have valid location data
- Try switching to another tab and back to refresh the map

**Issue: App is slow to load photos**
- This is normal for large photo libraries, especially with iCloud
- Progress is shown in the console (View > Debug Area > Activate Console)
- The app will cache thumbnails for faster subsequent loads

---

## Requirements

**iOS Version:** iOS 16.0 or later

**Device:** iPhone or iPad

**Permissions:** Photo Library access (read-only)

**Storage:** Minimal (only caches trip metadata and geocoding results)

**iCloud:** Optional, but supported for photos stored in iCloud Photo Library

---

## Privacy

**Local Processing** - All photo analysis happens on your device. No photos are uploaded to any server.

**Minimal Data** - Only trip metadata and geocoding results are cached locally.

**No Tracking** - The app does not collect any analytics or user data.

**Secure** - Uses Apple's PhotoKit framework with proper authorization.

---

## Support

For questions, issues, or feature requests, please check the following documentation:

- `FIXES_SUMMARY.md` - Detailed technical breakdown of all fixes
- `QUICK_FIXES_REFERENCE.md` - User-friendly guide to what was fixed and how to test

---

## Version History

**v1.1.0 (October 4, 2025)** - Fixed AttributeGraph cycle, map crashes, trip detection, and iCloud loading

**v1.0.0 (October 2, 2025)** - Initial release with basic trip organization and map view

---

## License

This project is provided as-is for personal use. Feel free to modify and customize it for your needs.

---

**Enjoy organizing your travel memories! 🌍✨**

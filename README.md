# 🌍 TripMemories - The Ultimate Trip Organizing App

**Automatically organize your photos into beautiful trip albums with smart AI clustering, comprehensive statistics, and stunning visualizations.**

---

## ✨ Features

### 🎯 Core Features
- **Smart Trip Detection** - Automatically clusters photos into trips based on location and date
- **Beautiful Timeline** - Browse your travels chronologically with year-based navigation
- **Travel Statistics** - Comprehensive analytics about your trips, destinations, and photos
- **Trip Categories** - Organize trips by type (Vacation, Business, Weekend, Adventure, Family, Friends, Solo)
- **Favorites** - Mark your favorite trips for quick access
- **Search & Filter** - Powerful search and filtering by name, location, category, and favorites

### ✏️ Trip Management
- **Custom Titles** - Override auto-generated trip names
- **Edit Details** - Modify category, add notes, and customize trip information
- **Delete Trips** - Remove trip albums (photos remain in your library)
- **Export to Albums** - Create native photo albums from trips
- **Share Trips** - Share your travel memories with friends and family

### 🎞️ Viewing Experience
- **Slideshow Mode** - Full-screen photo presentations with auto-play
- **Grid View** - Beautiful photo grids with lazy loading
- **Trip Cards** - Stunning cards with cover photos, stats, and category badges
- **Smooth Animations** - Delightful transitions and interactions throughout

### 📊 Statistics & Insights
- **Travel Overview** - Total trips, countries visited, days traveled, and photos taken
- **Yearly Breakdown** - Visual charts showing trips per year
- **Category Distribution** - See how your trips are categorized
- **Top Destinations** - Your most visited places
- **Photo Analytics** - Average photos per trip, longest trip, and more

### 🎨 Beautiful Design
- **Modern UI** - Clean, intuitive interface with iOS design guidelines
- **Color-Coded Categories** - Each trip category has its own color and icon
- **Gradient Accents** - Beautiful gradients throughout the app
- **Dark Mode Ready** - Fully supports system appearance
- **Responsive Layout** - Adapts to different screen sizes

---

## 🚀 Getting Started

### Prerequisites
- iOS 16.0 or later
- Xcode 15.0 or later
- Apple Developer account (for device testing)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/N0v4ont0p/TripMemories-iOS.git
   cd TripMemories-iOS
   ```

2. **Open in Xcode**
   ```bash
   open TripMemories.xcodeproj
   ```

3. **Configure Signing**
   - Select the project in Xcode
   - Go to "Signing & Capabilities"
   - Select your development team
   - Xcode will automatically manage provisioning

4. **Build and Run**
   - Select your target device
   - Press `Cmd+R` or click the Run button
   - Grant photo library access when prompted

---

## 📱 How to Use

### First Launch
1. **Grant Photo Access** - Allow the app to access your photo library
2. **Set Home Location** - Enter your home address for accurate trip detection
3. **Organize Photos** - Tap "Organize Photos" to create your first trips

### Organizing Trips
- The app automatically clusters photos based on:
  - **Distance from home** (30km minimum)
  - **Location proximity** (150km grouping radius)
  - **Date continuity** (4-day maximum gap)
  - **Minimum photos** (2 photos per trip)

### Browsing Trips
- **Trips Tab** - View all trips with search, filters, and sorting
- **Timeline Tab** - Browse chronologically by year
- **Stats Tab** - Explore your travel statistics and insights

### Editing Trips
1. Open a trip
2. Tap the edit button (pencil icon)
3. Modify title, category, notes, or favorite status
4. Save changes

### Slideshow Mode
1. Open a trip
2. Tap the menu button (three dots)
3. Select "Slideshow"
4. Use playback controls or tap to show/hide controls

---

## 🎨 Trip Categories

| Category | Icon | Color | Use Case |
|----------|------|-------|----------|
| **Vacation** | ☀️ | Orange | Long leisure trips |
| **Business** | 💼 | Blue | Work-related travel |
| **Weekend** | 📅 | Green | Short 2-3 day trips |
| **Adventure** | ⛰️ | Red | Outdoor activities |
| **Family** | 👨‍👩‍👧 | Purple | Family gatherings |
| **Friends** | 👥 | Pink | Trips with friends |
| **Solo** | 🚶 | Indigo | Solo adventures |
| **Other** | ⭐ | Gray | Miscellaneous |

Categories are automatically assigned based on trip duration and location keywords, but can be manually changed.

---

## 🔧 Technical Details

### Architecture
- **SwiftUI** - Modern declarative UI framework
- **MVVM Pattern** - Clean separation of concerns
- **Async/Await** - Modern concurrency for smooth performance
- **Photos Framework** - Native photo library integration
- **CoreLocation** - Location services and geocoding

### Key Components

#### Models
- `Trip` - Trip data model with categories, favorites, and notes
- `Photo` - Photo metadata wrapper
- `UserSettings` - App configuration and preferences
- `TripCategory` - Enum for trip categorization

#### ViewModels
- `TripViewModel` - Manages trip state and operations
- `PhotoLibraryViewModel` - Handles photo library access and loading

#### Services
- `TripClusteringService` - Smart trip detection algorithm
- `PhotoLibraryService` - Photo loading and thumbnail generation
- `PersistenceService` - Data caching and storage

#### Views
- `TripListView` - Main trips list with search and filters
- `TimelineView` - Chronological trip timeline
- `StatisticsView` - Travel analytics and insights
- `TripDetailView` - Detailed trip view with photos
- `TripEditView` - Trip editing interface
- `SlideshowView` - Full-screen photo slideshow

### Performance Optimizations
- **Lazy Loading** - Photos load on-demand
- **Thumbnail Caching** - Fast image loading with memory cache
- **Batch Processing** - Efficient photo thumbnail generation
- **Background Tasks** - Non-blocking UI during organization
- **Geocoding Cache** - Reduces API calls for location names

---

## 🎯 Clustering Algorithm

The app uses a sophisticated multi-step clustering algorithm:

1. **Home Filtering** - Excludes photos within 30km of home
2. **Date Sorting** - Orders photos chronologically
3. **Location Grouping** - Groups photos within 150km radius
4. **Date Continuity** - Merges groups with <4 day gaps
5. **Cluster Merging** - Combines nearby overlapping clusters
6. **Geocoding** - Resolves location names with smart formatting
7. **Category Assignment** - Auto-categorizes based on duration and keywords

### Configuration
```swift
minTripDistance: 30km        // Minimum distance from home
locationGroupingRadius: 150km // Photo grouping radius
maxDayGap: 4 days            // Maximum gap between photos
minPhotosPerTrip: 2          // Minimum photos per trip
nearbyTripMergeRadius: 200km // Cluster merging radius
```

---

## 📊 Statistics Tracked

- Total number of trips
- Unique countries/destinations visited
- Total days traveled
- Total photos in trips
- Trips per year (with visual charts)
- Trips per category (with distribution)
- Top 5 destinations
- Average photos per trip
- Longest trip duration
- Trip with most photos

---

## 🎨 UI Components

### Custom Components
- `EnhancedTripCard` - Beautiful trip card with cover photo and stats
- `TimelineTripCard` - Timeline-specific trip card with indicator
- `StatCard` - Statistics card with icon and gradient
- `FilterChip` - Category and filter chips
- `InfoRow` - Information row with icon and label

### Design System
- **Colors** - Category-specific colors with gradients
- **Typography** - SF Pro with semantic sizing
- **Spacing** - Consistent 8pt grid system
- **Shadows** - Subtle depth with layered shadows
- **Animations** - Spring-based natural motion

---

## 🔒 Privacy

- **Local Processing** - All clustering happens on-device
- **No Cloud Storage** - Photos never leave your device
- **Minimal Permissions** - Only photo library access required
- **Cached Data** - Trips cached locally for offline access
- **User Control** - Full control over trip organization

---

## 🐛 Troubleshooting

### Trips Not Appearing
- Ensure photos have location data
- Check home location is set correctly
- Verify photos are >30km from home
- Try reorganizing with "Reorganize" button

### Slow Performance
- Reduce number of photos in library
- Clear app cache and reorganize
- Ensure sufficient device storage
- Close other apps to free memory

### Location Names Wrong
- Check device location services
- Verify internet connection for geocoding
- Clear geocoding cache and reorganize

---

## 🚧 Known Limitations

- Requires photos with GPS metadata
- Geocoding requires internet connection
- Large photo libraries (>10,000 photos) may take time to organize
- iCloud photos must be downloaded to device

---

## 🎯 Future Enhancements

- [ ] Trip merging and splitting
- [ ] Manual photo addition/removal
- [ ] Trip sharing with iCloud
- [ ] Export as PDF/slideshow
- [ ] Travel route visualization
- [ ] Budget tracking per trip
- [ ] Weather data integration
- [ ] Social media integration

---

## 📄 License

This project is open source and available under the MIT License.

---

## 👨‍💻 Author

**George** (胡敬知)
- Age: 13 (born March 2012)
- Interests: F1 Racing 🏎️, Rowing 🚣

---

## 🙏 Acknowledgments

- Apple's Photos Framework documentation
- SwiftUI community
- CoreLocation and MapKit teams
- All beta testers and contributors

---

## 📞 Support

For issues, questions, or feature requests, please open an issue on GitHub.

**Enjoy organizing your travel memories! ✈️📸🌍**

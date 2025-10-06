import SwiftUI

struct TripEditView: View {
    let trip: Trip
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripViewModel: TripViewModel
    
    @State private var customTitle: String
    @State private var selectedCategory: TripCategory
    @State private var notes: String
    @State private var isFavorite: Bool
    
    init(trip: Trip) {
        self.trip = trip
        _customTitle = State(initialValue: trip.customTitle ?? "")
        _selectedCategory = State(initialValue: trip.category)
        _notes = State(initialValue: trip.notes ?? "")
        _isFavorite = State(initialValue: trip.isFavorite)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Name") {
                    TextField("Custom name (optional)", text: $customTitle)
                    
                    if !customTitle.isEmpty {
                        Text("Original: \(trip.title)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(TripCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Toggle(isOn: $isFavorite) {
                        Label("Favorite", systemImage: "star.fill")
                    }
                }
            }
            .navigationTitle("Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        tripViewModel.updateTripTitle(trip: trip, newTitle: customTitle)
        tripViewModel.updateTripCategory(trip: trip, newCategory: selectedCategory)
        tripViewModel.updateTripNotes(trip: trip, newNotes: notes)
        
        if isFavorite != trip.isFavorite {
            tripViewModel.toggleFavorite(trip: trip)
        }
    }
}

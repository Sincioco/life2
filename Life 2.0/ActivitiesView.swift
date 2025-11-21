// ————————————————————————————————————————————————————————————————————————————————————————————————————
//                                      Life 2.0 - Activity View
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Programmed By:  Louiery R. Sincioco                                                     Version: 1.0
// Programmed Date:  November 19, 2025                                                      For: iOS 26
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Purpose:  A view to render activities.
// ————————————————————————————————————————————————————————————————————————————————————————————————————

import Foundation
import SwiftUI
import SwiftData

// MARK: - ListView
struct ActivitiesView: View {
    
    @Query var Activities: [Activity]
    @State private var isPresentingAddActivity = false      // ← NEW
    @State private var searchText: String = ""
    
    // --------------------------------
    // Filter then group by Category
    // --------------------------------
    private var filteredActivities: [Activity] {
        guard !searchText.isEmpty else { return Activities }
        
        return Activities.filter { activity in
            activity.name.localizedCaseInsensitiveContains(searchText) ||
            activity.category.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var groupedByCategory: [String: [Activity]] {
        Dictionary(grouping: filteredActivities, by: { $0.category })
    }
    
    var body: some View {
        NavigationStack{
            Group {
                // --------------------------------
                // Render the list
                List {
                    
                    // --------------------------------
                    // Group by Category
                    ForEach(groupedByCategory.keys.sorted(), id: \.self) { category in
                        
                        // --------------------------------
                        // Add a Section Header for each Category
                        Section(header: Text(category)) {
                            
                            // --------------------------------
                            // Render the items under each Category
                            ForEach(groupedByCategory[category] ?? []) { activity in
                                
                                // --------------------------------
                                // Use a Custom Row that animates the graph
                                ActivityRow(activity: activity)
                            }
                            .padding(0)
                        }
                        .contentShape(Rectangle())
                    }
                }
                .listRowSeparator(.hidden)
                
                // --------------------------------
                // Search
                .searchable(text: $searchText,
                            placement: .navigationBarDrawer(displayMode: .automatic),
                            prompt: "Search activities")
                
            }
            .navigationTitle("Activities")
            
            // --------------------------------
            // Toolbar Items
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        
                    } label: {
                        Image(systemName: "house")
                    }
                    .accessibilityLabel("Home")
                }
                ToolbarItem(placement: .automatic) {
                    Button {
                        
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                    .accessibilityLabel("Filter")
                }
                
                ToolbarSpacer()
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingAddActivity = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            // --------------------------------
            // Present sheet to add a new Activity
            // --------------------------------
            .sheet(isPresented: $isPresentingAddActivity) {
                AddActivityView()   // defined below
            }
        }
    }
}

// MARK: - Activity Row with animated gauge
struct ActivityRow: View {
    
    let activity: Activity
    
    @State private var animatedProgress: Double = 0
    @State private var hasAnimated = false
    
    var body: some View {
        
        HStack {
            
            // --------------------------------
            // Activity Icon
            // --------------------------------
            Image(systemName: activity.icon)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
                .padding(0)
            
            Spacer(minLength: 20)
            
            // --------------------------------
            // Activity Name and Progress
            // --------------------------------
            VStack(alignment: .leading) {
                
                // --------------------------------
                // Activity Name
                Text(activity.name)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // --------------------------------
                // Activity Progress
                Gauge(value: animatedProgress, in: 0...100) {
                    EmptyView()                                 // no label
                } currentValueLabel: {
                    EmptyView()                                 // we'll draw our own text
                }
                .gaugeStyle(.automatic)
                .tint(.green)                                   // green fill
                .frame(maxWidth: .infinity)
                
                // --------------------------------
                // Draw Text on top of the guage
                .overlay {                                      // center the score text on top
                    Text("\(Int(animatedProgress))%")
                        .monospacedDigit()
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
            }
        }
        .onAppear {
            
            // --------------------------------
            // Only animate once per row
            guard !hasAnimated else { return }
            hasAnimated = true
            
            // --------------------------------
            // Animate bar graph from 0 to the actual value
            animatedProgress = 0
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = activity.progress
            }
        }
    }
}

import SwiftUI
import SwiftData

// MARK: - Add Activity View
struct AddActivityView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Available categories
    private let categories = [
        "Bills",
        "Fitness",
        "Learning",
        "Maintenance",
        "Personal",
        "Work",
        "Others"
    ]
    
    // Form fields
    @State private var name: String = ""
    @State private var icon: String = "figure.walk"
    @State private var progress: Double = 0
    @State private var recurrence: String = "Daily"
    @State private var category: String = "Fitness"   // default
    @State private var notes: String = ""
    
    // Sheet state
    @State private var isPresentingIconPicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                
                // ----------------------------------------------------
                // Activity Section
                // ----------------------------------------------------
                Section("Activity") {
                    TextField("Name", text: $name)
                    
                    // Icon "field" that opens a picker sheet
                    Button {
                        isPresentingIconPicker = true
                    } label: {
                        HStack {
                            Text("Icon")
                            Spacer()
                            Image(systemName: icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            Text(icon)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    
                    TextField("Recurrence", text: $recurrence)
                }
                
                // ----------------------------------------------------
                // Progress Section
                // ----------------------------------------------------
                Section("Progress") {
                    VStack(spacing: 12) {
                        HStack {
                            Spacer()
                            Text("\(Int(progress))%")
                                .monospacedDigit()
                            Spacer()
                        }
                        
                        Slider(value: $progress, in: 0...100, step: 1) {
                            Text("Progress")
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowSeparator(.hidden)
                }
                
                // ----------------------------------------------------
                // Notes
                // ----------------------------------------------------
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("Add Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveActivity()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            // Icon picker sheet
            .sheet(isPresented: $isPresentingIconPicker) {
                NavigationStack {
                    IconPickerView(selectedIcon: $icon)
                }
            }
        }
    }
    
    // ------------------------------------------------------------
    // Save a new Activity to SwiftData
    // ------------------------------------------------------------
    private func saveActivity() {
        let now = Date()
        
        let newActivity = Activity(
            name: name,
            icon: icon,
            progress: progress,
            recurrence: recurrence,
            category: category,
            notes: notes,
            dateCreated: now,
            dateModified: now
        )
        
        modelContext.insert(newActivity)
        dismiss()
    }
}

// MARK: - Icon Picker View

struct IconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIcon: String
    @State private var searchText: String = ""
    
    // A small, extensible set of SF Symbols (add more as needed)
    private let allSymbols: [String] = [
        // Fitness / Health
        "figure.walk", "figure.run", "heart.fill", "bolt.heart",
        // Bills / Money
        "creditcard", "creditcard.fill", "banknote", "dollarsign.circle.fill",
        // Work / Productivity
        "calendar", "clock", "briefcase.fill", "laptopcomputer",
        // Learning
        "book.fill", "graduationcap.fill",
        // Maintenance
        "wrench.fill", "gearshape.fill", "paintbrush.fill",
        // Personal / Misc
        "house.fill", "car.fill", "cart.fill", "star.fill",
        "bell.fill", "person.fill", "person.2.fill"
    ]
    
    private var filteredSymbols: [String] {
        guard !searchText.isEmpty else { return allSymbols }
        return allSymbols.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 56), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredSymbols, id: \.self) { symbol in
                    Button {
                        selectedIcon = symbol
                        dismiss()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: symbol)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 28)
                            
                            Text(symbol)
                                .font(.caption2)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Choose Icon")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search symbols")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }
}

// MARK: - Preview code for Canvas
#Preview {
    let previewContainer: ModelContainer = {
        let schema = Schema([Activity.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        
        let container = try! ModelContainer(for: schema, configurations: config)
        
        // Insert test data
        for event in Activity.sampleData {
            container.mainContext.insert(event)
        }
        
        return container
    }()
    
    MainView()   // ← make sure this matches the struct name
        .modelContainer(previewContainer)
}

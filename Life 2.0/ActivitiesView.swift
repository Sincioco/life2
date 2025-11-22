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
    @Environment(\.modelContext) private var modelContext
    @Query var Activities: [Activity]
    @State private var isPresentingAddActivity = false      // ← NEW
    @State private var searchText: String = ""
    @State private var showEmptyPrompt: Bool = true
    @State private var reloadID = UUID()
    
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
                // --------------------------------
                List {
                    
                    // --------------------------------
                    // Group by Category
                    ForEach(groupedByCategory.keys.sorted(), id: \.self) { category in
                        
                        // --------------------------------
                        // Add a Section Header for each Category
//                        Section(header: Text(category)) {
//                            
//                            // --------------------------------
//                            // Render the items under each Category
//                            ForEach(groupedByCategory[category] ?? []) { activity in
//                                
//                                // --------------------------------
//                                // Use a Custom Row that animates the graph
//                                ActivityRow(activity: activity)
//                            }
//                            .padding(0)
//                            
//                            
//                        }
                        Section(header: Text(category)) {
                            
                            if let activitiesInSection = groupedByCategory[category] {
                                
                                ForEach(activitiesInSection) { activity in
                                    NavigationLink {
                                        EditActivityView(activity: activity)
                                    } label: {
                                        ActivityRow(activity: activity)
                                    }
                                }
                                .onDelete { indexSet in
                                    for index in indexSet {
                                        let toDelete = activitiesInSection[index]
                                        modelContext.delete(toDelete)   // ❌ no withAnimation
                                    }
                                }
                                .padding(0)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    
                }
                .id(reloadID)
                .listRowSeparator(.hidden)
                
                // --------------------------------
                // Search
                .searchable(text: $searchText,
                            placement: .navigationBarDrawer(displayMode: .automatic),
                            prompt: "Search activities")
                
                
                .navigationTitle("Activities")
                .overlay {
                    if Activities.isEmpty && showEmptyPrompt {
                        // --------------------------------
                        // Empty state prompt
                        // --------------------------------
                        VStack(spacing: 16) {
                            Text("No Activies Found")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("Create sample activities for you to start with?")
                                .multilineTextAlignment(.center)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 24)
                            
                            HStack(spacing: 16) {
                                
                                // Later button
                                Button("Later") {
                                    withAnimation {
                                        showEmptyPrompt = false
                                    }
                                }
                                .buttonStyle(.bordered)
                                
                                // Yes button (default action)
                                Button("Yes") {
                                    withAnimation {
                                        generateStarterActivities()
                                        showEmptyPrompt = false
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .keyboardShortcut(.defaultAction)   // makes "Yes" the default action
                            }
                            .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .onChange(of: Activities.count) { oldValue, newValue in
                    if newValue == 0 {
                        // List just became empty → allow the prompt again
                        showEmptyPrompt = true
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .activityDidChange)) { _ in
                    reloadID = UUID()
                }
            }
            
            
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
    
    // MARK: - Starter Activities
    
    private func generateStarterActivities() {
        let now = Date()
        
        let starters: [Activity] = [
            Activity(
                name: "Morning Run",
                icon: "figure.run",
                progress: Double(Int.random(in: 10...60)),
                count: Int.random(in: 0...5),
                maxCount: Int.random(in: 5...10),
                recurrence: "Daily",
                category: "Fitness",
                notes: "Light 5km run to start the day.",
                dateCreated: now,
                dateModified: now
            ),
            Activity(
                name: "Pay Electric Bill",
                icon: "bolt.fill",
                progress: Double(Int.random(in: 0...10)),
                count: Int.random(in: 0...5),
                maxCount: Int.random(in: 5...10),
                recurrence: "Monthly",
                category: "Bills",
                notes: "Due near the end of the month.",
                dateCreated: now,
                dateModified: now
            ),
            Activity(
                name: "Learn Something New",
                icon: "book.fill",
                progress: Double(Int.random(in: 20...70)),
                count: Int.random(in: 0...5),
                maxCount: Int.random(in: 5...10),
                recurrence: "Daily",
                category: "Learning",
                notes: "Spend at least 30 minutes building UIs.",
                dateCreated: now,
                dateModified: now
            ),
            Activity(
                name: "Family Dinner",
                icon: "person.3.fill",
                progress: Double(Int.random(in: 0...30)),
                count: Int.random(in: 0...5),
                maxCount: Int.random(in: 5...10),
                recurrence: "Weekly",
                category: "Personal",
                notes: "Device-free dinner with the family.",
                dateCreated: now,
                dateModified: now
            ),
            Activity(
                name: "Weekly Planning",
                icon: "calendar.badge.clock",
                progress: Double(Int.random(in: 0...40)),
                count: Int.random(in: 0...5),
                maxCount: Int.random(in: 5...10),
                recurrence: "Weekly",
                category: "Work",
                notes: "Plan tasks and priorities for the week.",
                dateCreated: now,
                dateModified: now
            )
        ]
        
        for activity in starters {
            modelContext.insert(activity)
        }
        // SwiftData auto-saves with the context; no explicit save call required
    }
}

// MARK: - Activity Row with animated gauge
struct ActivityRow: View {
    
    @Environment(\.modelContext) private var modelContext   // ← needed to delete from SwiftData
    
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
                
                // Activity Name
                Text(activity.name)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Activity Progress
                Gauge(value: animatedProgress, in: 0...100) {
                    EmptyView()                                 // no label
                } currentValueLabel: {
                    EmptyView()                                 // we'll draw our own text
                }
                .gaugeStyle(.automatic)
                .tint(.green)                                   // green fill
                .frame(maxWidth: .infinity)
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
            // Only animate once per row
            guard !hasAnimated else { return }
            hasAnimated = true
            
            // Animate bar graph from 0 to the actual value
            animatedProgress = 0
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = activity.progress
            }
        }
        //        // --------------------------------
        //        // Swipe left to delete
        //        // --------------------------------
        //        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
        //            Button(role: .destructive) {
        //                // ❌ no explicit withAnimation here
        //                modelContext.delete(activity)
        //            } label: {
        //                Label("Delete", systemImage: "trash")
        //            }
        //        }
    }
}

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
    
    private let recurrencies = [
        "Daily",
        "Weekly",
        "Monthly",
        "Yearly"
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
                    
                    Picker("Recurrence", selection: $recurrence) {
                        ForEach(recurrencies, id: \.self) { rec in
                            Text(rec).tag(rec)
                        }
                    }
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
            count: Int.random(in: 0...5),
            maxCount: Int.random(in: 5...10),
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

// MARK: - Notifications
extension Notification.Name {
    static let activityDidChange = Notification.Name("activityDidChange")
}

// MARK: - Edit Activity View
struct EditActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var activity: Activity

    // Available categories (same as AddActivityView)
    private let categories = [
        "Bills",
        "Fitness",
        "Learning",
        "Maintenance",
        "Personal",
        "Work",
        "Others"
    ]
    
    private let recurrencies = [
        "Daily",
        "Weekly",
        "Monthly",
        "Yearly"
    ]

    // Sheet state
    @State private var isPresentingIconPicker = false
    @State private var showDeleteAlert = false

    var body: some View {
        Form {
            Section("Activity") {
                TextField("Name", text: $activity.name)

                Button {
                    isPresentingIconPicker = true
                } label: {
                    HStack {
                        Text("Icon")
                        Spacer()
                        Image(systemName: activity.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text(activity.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                Picker("Category", selection: $activity.category) {
                    ForEach(categories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
                
                Picker("Recurrence", selection: $activity.recurrence) {
                    ForEach(recurrencies, id: \.self) { rec in
                        Text(rec).tag(rec)
                    }
                }

            }

            Section("Progress") {
                VStack(spacing: 12) {
                    HStack {
                        Spacer()
                        Text("\(Int(activity.progress))%")
                            .monospacedDigit()
                        Spacer()
                    }

                    Slider(value: $activity.progress, in: 0...100, step: 1) {
                        Text("Progress")
                    }
                }
                .padding(.vertical, 4)
                .listRowSeparator(.hidden)
            }

            Section("Notes") {
                TextField("Notes", text: $activity.notes, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }
            
            Section { 
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Text("Delete Activity")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("Edit Activity")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    // Update modification date and notify list to refresh
                    activity.dateModified = Date()
                    try? modelContext.save()
                    NotificationCenter.default.post(name: .activityDidChange, object: nil)
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $isPresentingIconPicker) {
            NavigationStack {
                IconPickerView(selectedIcon: $activity.icon)
            }
        }
        .alert("Delete Activity?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                // Perform delete, notify, and dismiss
                modelContext.delete(activity)
                try? modelContext.save()
                NotificationCenter.default.post(name: .activityDidChange, object: nil)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
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


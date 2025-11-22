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
import UIKit
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
        
        func randomizedDate(for recurrence: String, now: Date) -> Date {
            switch recurrence {
            case "Daily":
                // between now and 23 hours ago
                let hours = Int.random(in: 0...23)
                return Calendar.current.date(byAdding: .hour, value: -hours, to: now) ?? now
            case "Weekly":
                // between now and 7 days ago
                let days = Int.random(in: 0...7)
                return Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
            case "Monthly":
                // between now and 30 days ago
                let days = Int.random(in: 0...30)
                return Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
            default:
                return now
            }
        }
        
        let starters: [Activity] = [
            Activity(
                name: "Morning Run",
                icon: "figure.run",
                count: 5,
                maxCount: 7,
                recurrence: "Weekly",
                category: "Fitness",
                notes: "Light 5km run to start the day.",
                dateCreated: randomizedDate(for: "Weekly", now: now),
                dateModified: randomizedDate(for: "Weekly", now: now)
            ),
            Activity(
                name: "Gym",
                icon: "dumbbell",
                count: 23,
                maxCount: 30,
                recurrence: "Monthly",
                category: "Fitness",
                notes: "30 mins in the gym",
                dateCreated: randomizedDate(for: "Monthly", now: now),
                dateModified: randomizedDate(for: "Monthly", now: now)
            ),
            Activity(
                name: "Learn Something New",
                icon: "book.fill",
                count: Int.random(in: 0...5),
                maxCount: 7,
                recurrence: "Weekly",
                category: "Learning",
                notes: "Spend at least 30 minutes reading.",
                dateCreated: randomizedDate(for: "Weekly", now: now),
                dateModified: randomizedDate(for: "Weekly", now: now)
            ),
            Activity(
                name: "Family Time",
                icon: "person.3.fill",
                count: Int.random(in: 1...6),
                maxCount: 7,
                recurrence: "Weekly",
                category: "Personal",
                notes: "Quality time with the family.",
                dateCreated: randomizedDate(for: "Weekly", now: now),
                dateModified: randomizedDate(for: "Weekly", now: now)
            ),
            Activity(
                name: "Weekly Planning",
                icon: "calendar.badge.clock",
                count: Int.random(in: 0...5),
                maxCount: 7,
                recurrence: "Weekly",
                category: "Work",
                notes: "Plan tasks and priorities for the week.",
                dateCreated: randomizedDate(for: "Weekly", now: now),
                dateModified: randomizedDate(for: "Weekly", now: now)
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
    @State private var showDeleteConfirm = false
    @State private var isDeletingVisual = false
    
    private var gaugeColor: Color {
        let value = activity.progress
        if value < 30 { return .red }
        else if value < 70 { return .yellow }
        else { return .green }
    }
    
    private var isModifiedToday: Bool {
        Calendar.current.isDateInToday(activity.dateModified)
    }
    
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
                .overlay {
                    if (activity.count > 0 && isModifiedToday) {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundStyle(.green)
                            .background(
                                Circle()
                                    .fill(.background)   // small backing to keep it readable
                            )
                            .offset(x: 26, y: -17)       // nudge slightly outwards
                    }
                }
            
            
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
                .tint(gaugeColor)                               // dynamic fill color
                .frame(maxWidth: .infinity)
                .padding(.top, -8)   // ← pulls gauge closer to the text
                .overlay {                                      // center the score text on top
                    Text("\(Int(animatedProgress))%")
                        .monospacedDigit()
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .padding(.top, -8)
                }
                
                HStack(alignment: .firstTextBaseline) {
                    Text("\(activity.recurrence): \(activity.count) of \(activity.maxCount)")
                    Spacer()
                    
                    if (activity.count > 0) {
                        HStack(spacing: 2) {
                            Text(activity.dateModified, style: .relative)
                            Text("ago")
                        }
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

        }
        .opacity(isDeletingVisual ? 0.0 : 1.0)
        .scaleEffect(isDeletingVisual ? 0.98 : 1.0)
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
        // --------------------------------
        // Swipe left to increment count + add delete button
        // --------------------------------
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            
            // Full-swipe performs this action
            let isDisabled = activity.count >= activity.maxCount
            
            if (isDisabled == false) {
                Button {
                    if activity.count < activity.maxCount {
                        activity.count += 1
                        activity.dateModified = Date()
                        try? modelContext.save()
                        NotificationCenter.default.post(name: .activityDidChange, object: nil)
                        let success = UINotificationFeedbackGenerator()
                        success.notificationOccurred(.success)
                    } else {
                        let warning = UINotificationFeedbackGenerator()
                        warning.notificationOccurred(.warning)
                    }
                } label: {
                    Label("Done", systemImage: "checkmark")
                }
                .tint(.green)
                .disabled(isDisabled)                  // Disable the Done / Checkmark button if the count has reached max count
            }
            
            Button {
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
        .alert("Delete Activity?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.12)) {
                    isDeletingVisual = true
                }
                // Delay actual deletion slightly to let the visual effect play
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        modelContext.delete(activity)
                    }
                    try? modelContext.save()
                    NotificationCenter.default.post(name: .activityDidChange, object: nil)
                    let error = UINotificationFeedbackGenerator()
                    error.notificationOccurred(.error)
                    // Reset visual state in case the row is reused in lists
                    isDeletingVisual = false
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
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
    @State private var count: Int = 0
    @State private var maxCount: Int = 7
    //@State private var progress: Double = 0  // ← REMOVED as per instruction
    
    @State private var recurrence: String = "Daily"
    @State private var category: String = "Fitness"   // default
    @State private var notes: String = ""
    
    // Sheet state
    @State private var isPresentingIconPicker = false
    
    // Computed progress based on count and maxCount
    private var computedProgress: Double {
        guard maxCount > 0 else { return 0 }
        let ratio = min(Double(count) / Double(maxCount), 1.0)
        return max(0, ratio) * 100
    }
    
    private var maxCountUpperBound: Int {
        switch recurrence {
        case "Daily": return 1
        case "Weekly": return 7
        case "Monthly": return 31
        case "Yearly": return 366
        default: return 100
        }
    }
    
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
                    
                    TextField("Count", value: $count, format: .number)
                        .keyboardType(.numberPad)
                    
                    TextField("Max Count", value: $maxCount, format: .number)
                        .keyboardType(.numberPad)
                    
                    HStack {
                        Gauge(value: computedProgress, in: 0...100) { EmptyView() } currentValueLabel: { EmptyView() }
                            .gaugeStyle(.automatic)
                            .tint(.green)
                        Text("\(Int(computedProgress))%")
                            .monospacedDigit()
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // ----------------------------------------------------
                // Progress Section
                // ----------------------------------------------------
                //                Section("Progress") {
                //                    VStack(spacing: 12) {
                //                        HStack {
                //                            Spacer()
                //                            Text("\(Int(computedProgress))%")
                //                                .monospacedDigit()
                //                            Spacer()
                //                        }
                //
                //                        Slider(value: .constant(computedProgress), in: 0...100, step: 1) {
                //                            Text("Progress")
                //                        }
                //                        .disabled(true)
                //                    }
                //                    .padding(.vertical, 4)
                //                    .listRowSeparator(.hidden)
                //                }
                
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
            count: count,
            maxCount: maxCount,
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
    
    // Computed progress based on count and maxCount
    private var computedProgress: Double {
        guard activity.maxCount > 0 else { return 0 }
        let ratio = min(Double(activity.count) / Double(activity.maxCount), 1.0)
        return max(0, ratio) * 100
    }
    
    private var maxCountUpperBound: Int {
        switch activity.recurrence {
        case "Daily": return 1
        case "Weekly": return 7
        case "Monthly": return 31
        case "Yearly": return 366
        default: return 100
        }
    }
    
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
                
                TextField("Count", value: $activity.count, format: .number)
                    .keyboardType(.numberPad)
                
                TextField("Max Count", value: $activity.maxCount, format: .number)
                    .keyboardType(.numberPad)
                
                HStack {
                    Gauge(value: computedProgress, in: 0...100) { EmptyView() } currentValueLabel: { EmptyView() }
                        .gaugeStyle(.automatic)
                        .tint(.green)
                    Text("\(Int(computedProgress))%")
                        .monospacedDigit()
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            //            Section("Progress") {
            //                VStack(spacing: 12) {
            //                    HStack {
            //                        Spacer()
            //                        Text("\(Int(computedProgress))%")
            //                            .monospacedDigit()
            //                        Spacer()
            //                    }
            //
            //                    Slider(value: .constant(computedProgress), in: 0...100, step: 1) {
            //                        Text("Progress")
            //                    }
            //                    .disabled(true)
            //                }
            //                .padding(.vertical, 4)
            //                .listRowSeparator(.hidden)
            //            }
            
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
                    // Removed validation guard
                    // Removed: activity.progress = computedProgress
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

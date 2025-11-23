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
    @State private var isPresentingAddActivity = false
    @State private var searchText: String = ""
    @State private var showEmptyPrompt: Bool = true
    @State private var reloadID = UUID()
    
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
        NavigationStack {
            Group {
                List {
                    ForEach(groupedByCategory.keys.sorted(), id: \.self) { category in
                        Section(header: Text(category)) {
                            if let activitiesInSection = groupedByCategory[category] {
                                ForEach(activitiesInSection) { activity in
                                    NavigationLink {
                                        EditActivityView(activity: activity)
                                    } label: {
                                        ActivityRow(activity: activity)
                                            .contentShape(Rectangle())
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        let isDisabled = activity.count >= activity.maxCount
                                        Button {
                                            if activity.count < activity.maxCount {
//                                                activity.count += 1
//                                                activity.dateModified = Date()
//                                                try? modelContext.save()
                                                activity.increment(in: modelContext)
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
                                        .disabled(isDisabled)
                                    }
                                }
                            }
                        }
                        .contentShape(Rectangle())
                    }
                }
                .id(reloadID)
                .listRowSeparator(.hidden)
                .searchable(text: $searchText,
                            placement: .navigationBarDrawer(displayMode: .automatic),
                            prompt: "Search activities")
                .navigationTitle("Activities")
                .overlay {
                    if Activities.isEmpty && showEmptyPrompt {
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
                                Button("Later") {
                                    withAnimation { showEmptyPrompt = false }
                                }
                                .buttonStyle(.bordered)
                                Button("Yes") {
                                    withAnimation {
                                        Activity.generateStarterActivities(in: modelContext)
                                        showEmptyPrompt = false
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .keyboardShortcut(.defaultAction)
                            }
                            .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .onChange(of: Activities.count) { oldValue, newValue in
                    if newValue == 0 { showEmptyPrompt = true }
                }
                .onReceive(NotificationCenter.default.publisher(for: .activityDidChange)) { _ in
                    reloadID = UUID()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { } label: { Image(systemName: "house") }
                        .accessibilityLabel("Home")
                }
                ToolbarItem(placement: .automatic) {
                    Button { } label: { Image(systemName: "line.3.horizontal.decrease") }
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
            .sheet(isPresented: $isPresentingAddActivity) {
                AddActivityView()
            }
        }
    }

    

    private func increment(_ activity: Activity) {
//        activity.count += 1
//        activity.dateModified = Date()
//        try? modelContext.save()
        activity.increment(in: modelContext)
        NotificationCenter.default.post(name: .activityDidChange, object: nil)
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
                    Text("\(activity.recurrence.rawValue): \(activity.count) of \(activity.maxCount)")
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
        // Removed swipeActions entirely as per instruction
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

    private let recurrencies = Recurrence.allCases

    // Sheet state
    
    // Segmented control selection
    private enum AddEditTab: String, CaseIterable, Identifiable {
        case activity = "Activity"
        case history = "History"
        case notes = "Notes"
        var id: String { rawValue }
    }
    @State private var selectedTab: AddEditTab = .activity
    
    @State private var isPresentingIconPicker = false
    
    // Form fields
    @State private var name: String = ""
    @State private var icon: String = "figure.walk"
    @State private var count: Int = 0
    @State private var maxCount: Int = 7
    //@State private var progress: Double = 0  // ← REMOVED as per instruction
    
    @State private var recurrence: Recurrence = .daily
    @State private var category: String = "Fitness"   // default
    @State private var notes: String = ""
    
    // Focus management
    @FocusState private var isNameFocused: Bool
    
    // Computed progress based on count and maxCount
    private var computedProgress: Double {
        guard maxCount > 0 else { return 0 }
        let ratio = min(Double(count) / Double(maxCount), 1.0)
        return max(0, ratio) * 100
    }
    
    var body: some View {
        NavigationStack {
            Form {
                
                Picker("Section", selection: $selectedTab) {
                    ForEach(AddEditTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                
                if selectedTab == .activity {
                    Section("Activity") {
                        TextField("Name", text: $name)
                            .focused($isNameFocused)
                        
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
                                Text(rec.rawValue).tag(rec)
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
                }
                
                // ----------------------------------------------------
                // Notes
                // ----------------------------------------------------
                if selectedTab == .notes {
                    Section("Notes") {
                        TextField("Notes", text: $notes, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                    }
                }
                
                if selectedTab == .history {
                    Section("History") {
                        Text("No history yet.")
                            .foregroundStyle(.secondary)
                    }
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
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isNameFocused = true
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
    
    // Sheet state
    
    // Segmented control selection
    private enum AddEditTab: String, CaseIterable, Identifiable {
        case activity = "Activity"
        case history = "History"
        case notes = "Notes"
        var id: String { rawValue }
    }
    @State private var selectedTab: AddEditTab = .activity
    
    @State private var isPresentingIconPicker = false
    @State private var showDeleteAlert = false
    
    // Track original values to allow cancel-on-back behavior
    @State private var originalName: String = ""
    @State private var originalIcon: String = ""
    @State private var originalCategory: String = ""
    @State private var originalNotes: String = ""
    @State private var didSave: Bool = false
    
    // Computed progress based on count and maxCount
    private var computedProgress: Double {
        guard activity.maxCount > 0 else { return 0 }
        let ratio = min(Double(activity.count) / Double(activity.maxCount), 1.0)
        return max(0, ratio) * 100
    }
    
    var body: some View {
        Form {
            
            Picker("Section", selection: $selectedTab) {
                ForEach(AddEditTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            
            if selectedTab == .activity {
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
                        ForEach(Recurrence.allCases, id: \.self) { rec in
                            Text(rec.rawValue).tag(rec)
                        }
                    }
                    
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
            }
            
            if selectedTab == .notes {
                Section("Notes") {
                    TextField("Notes", text: $activity.notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            
            if selectedTab == .history {
                Section("History") {
                    Text("No history yet.")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                Button {
                    // Increment count and record completion in history
//                    activity.count += 1
//                    activity.dateModified = Date()
//                    // If Activity provides a record API, call it to log history
//                    activity.recordCompletion(on: Date(), in: modelContext)
//                    try? modelContext.save()
                    activity.increment(in: modelContext)
                    NotificationCenter.default.post(name: .activityDidChange, object: nil)
                } label: {
                    Label("Increment", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                //.buttonStyle(.borderedProminent)
                //.tint(.green)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))

            Section {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                //.tint(.red)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        .navigationTitle("Edit Activity")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
//            ToolbarItem(placement: .cancellationAction) {
//                Button("Cancel") {
//                    dismiss()
//                }
//            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    didSave = true
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
        .onAppear {
            originalName = activity.name
            originalIcon = activity.icon
            originalCategory = activity.category
            originalNotes = activity.notes
            didSave = false
        }
        .onDisappear {
            if didSave == false {
                activity.name = originalName
                activity.icon = originalIcon
                activity.category = originalCategory
                activity.notes = originalNotes
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
        let schema = Schema([Activity.self, ActivityHistory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        
        let container = try! ModelContainer(for: schema, configurations: config)
        
        // Insert test data
//        for event in Activity.sampleData {
//            container.mainContext.insert(event)
//        }
        
        return container
    }()
    
    ActivitiesView()
        .modelContainer(previewContainer)
}


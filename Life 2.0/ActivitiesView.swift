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
    @State private var pendingDelete: Activity? = nil
    @State private var isShowingDeleteAlert: Bool = false
    @State private var selectedCategory: String? = nil
    
    private var filteredActivities: [Activity] {
        let base = Activities
        let categoryFiltered: [Activity]
        if let selected = selectedCategory, !selected.isEmpty {
            categoryFiltered = base.filter { $0.category == selected }
        } else {
            categoryFiltered = base
        }
        guard !searchText.isEmpty else { return categoryFiltered }
        return categoryFiltered.filter { activity in
            activity.name.localizedCaseInsensitiveContains(searchText) ||
            activity.category.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var uniqueCategories: [String] {
        Array(Set(Activities.map { $0.category })).sorted()
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
                                        
                                        
                                        // Existing Done button
                                        let isDisabled = activity.count >= activity.maxCount
                                        Button {
                                            if activity.count < activity.maxCount {
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
                                        
                                        // Delete button (appears to the left of the Done button)
                                        Button(role: .destructive) {
                                            pendingDelete = activity
                                            isShowingDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
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
                .alert("Delete Activity?", isPresented: $isShowingDeleteAlert, presenting: pendingDelete) { activity in
                    Button("Delete", role: .destructive) {
                        modelContext.delete(activity)
                        try? modelContext.save()
                        NotificationCenter.default.post(name: .activityDidChange, object: nil)
                        let error = UINotificationFeedbackGenerator()
                        error.notificationOccurred(.error)
                        pendingDelete = nil
                    }
                    Button("Cancel", role: .cancel) {
                        pendingDelete = nil
                    }
                } message: { _ in
                    Text("This action cannot be undone.")
                }
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
                    Menu {
                        // Clear filter
                        Button {
                            selectedCategory = nil
                        } label: {
                            Label("All Categories", systemImage: selectedCategory == nil ? "checkmark" : "line.3.horizontal.decrease.circle.fill"
                            )
                        }
                        // List unique categories
                        ForEach(uniqueCategories, id: \.self) { cat in
                            Button {
                                selectedCategory = cat
                            } label: {
                                if selectedCategory == cat {
                                    Label(cat, systemImage: "checkmark")
                                } else {
                                    Text(cat)
                                }
                            }
                        }
                    } label: {
                        if let selected = selectedCategory {
                            Label(selected, systemImage: "line.3.horizontal.decrease.circle.fill")
                        } else {
                            Image(systemName: selectedCategory == nil ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill")
                        }
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
    
    
    @State private var isPresentingIconPicker = false
    
    // Form fields
    @State private var name: String = ""
    @State private var icon: String = "figure.walk"
    @State private var count: Int = 0
    @State private var maxCount: Int = 7
    //@State private var progress: Double = 0  // ← REMOVED as per instruction
    
    @State private var recurrence: Recurrence = .weekly
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

                    HStack(spacing: 16) {
                        Gauge(value: computedProgress, in: 0...100) { EmptyView() } currentValueLabel: { EmptyView() }
                            .gaugeStyle(.automatic)
                            .tint(.green)
                        Text("\(Int(computedProgress))%")
                            .monospacedDigit()
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: recurrence) { _, newValue in
                    switch newValue {
                    case .daily:   maxCount = 1
                    case .weekly:  maxCount = 7
                    case .monthly: maxCount = 31
                    case .yearly:  maxCount = 366
                    case .none:    maxCount = 0
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
            maxCount: maxCount,
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
        var id: String { rawValue }
    }
    @State private var selectedTab: AddEditTab = .activity
    
    @State private var isPresentingIconPicker = false
    @State private var showDeleteAlert = false
    @State private var showDeleteAllAlert = false
    
    @State private var isPresentingAddHistory = false
    @State private var newHistoryDate: Date = Date()
    
    // Added states for editing existing history entry
    @State private var editingHistory: ActivityHistory? = nil
    @State private var editingHistoryDate: Date = Date()
    
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
    
    private var sortedHistories: [ActivityHistory] {
        activity.histories.sorted { $0.dateCompleted > $1.dateCompleted }
    }
    
    var body: some View {
        
        Picker("Section", selection: $selectedTab) {
            ForEach(AddEditTab.allCases) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding()
        
        Form {
            
            
            
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
                    
                    TextField("Max Count", value: $activity.maxCount, format: .number)
                        .keyboardType(.numberPad)
                    
                    
                    Gauge(value: computedProgress, in: 0...100) { EmptyView() } currentValueLabel: { EmptyView() }
                        .gaugeStyle(.automatic)
                        .tint(.green)
                        .overlay {
                            Text("\(Int(computedProgress))%")
                                .monospacedDigit()
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }
                    
                    TextField("Notes", text: $activity.notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                    
                }
                .onChange(of: activity.recurrence) { _, newValue in
                    switch newValue {
                    case .daily:   activity.maxCount = 1
                    case .weekly:  activity.maxCount = 7
                    case .monthly: activity.maxCount = 31
                    case .yearly:  activity.maxCount = 366
                    case .none:    activity.maxCount = 0
                    }
                }
            }
            
            
            if selectedTab == .history {
                Section("History") {
                    if sortedHistories.isEmpty {
                        Text("No history yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sortedHistories) { history in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: activity.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(.blue)
                                    .padding(.top, 2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(history.dateCompleted, style: .date)
                                        .font(.subheadline)
                                    Text(history.dateCompleted, style: .time)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 2)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingHistory = history
                                editingHistoryDate = history.dateCompleted
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    modelContext.delete(history)
                                    try? modelContext.save()
                                    NotificationCenter.default.post(name: .activityDidChange, object: nil)
                                    let success = UINotificationFeedbackGenerator()
                                    success.notificationOccurred(.success)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                // Random history generator below the History list
                Section {
                    Button {
                        generateRandomHistories()
                    } label: {
                        Label("Random History", systemImage: "sparkles")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            
            if selectedTab == .activity {
                Section {
                    Button {
                        activity.increment(in: modelContext)
                        try? modelContext.save()
                        NotificationCenter.default.post(name: .activityDidChange, object: nil)
                        dismiss()
                    } label: {
                        Label("Increment", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
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
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                
#if DEBUG
                Section {
                    Button(role: .destructive) {
                        showDeleteAllAlert = true
                    } label: {
                        Label("Delete All", systemImage: "trash.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
#endif
                
            }
        }
        .navigationTitle("Edit Activity")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if selectedTab == .activity {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        didSave = true
                        activity.dateModified = Date()
                        try? modelContext.save()
                        NotificationCenter.default.post(name: .activityDidChange, object: nil)
                        dismiss()
                    }
                }
            } else if selectedTab == .history {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newHistoryDate = Date()
                        isPresentingAddHistory = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add History")
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
        .sheet(isPresented: $isPresentingAddHistory) {
            NavigationStack {
                Form {
                    Section("New History Entry") {
                        DatePicker("Completed On", selection: $newHistoryDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                .navigationTitle("Add History")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { isPresentingAddHistory = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let entry = ActivityHistory(activity: activity, dateCompleted: newHistoryDate)
                            modelContext.insert(entry)
                            try? modelContext.save()
                            NotificationCenter.default.post(name: .activityDidChange, object: nil)
                            isPresentingAddHistory = false
                        }
                    }
                }
            }
        }
        .sheet(item: $editingHistory) { history in
            NavigationStack {
                Form {
                    Section("Edit History Entry") {
                        DatePicker("Completed On", selection: $editingHistoryDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                .navigationTitle("Edit History")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { editingHistory = nil }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            history.dateCompleted = editingHistoryDate
                            history.dateRecorded = Date()
                            try? modelContext.save()
                            NotificationCenter.default.post(name: .activityDidChange, object: nil)
                            editingHistory = nil
                        }
                    }
                }
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
        .alert("Delete ALL activities and history?", isPresented: $showDeleteAllAlert) {
            Button("Delete All", role: .destructive) {
                do {
                    let descriptor = FetchDescriptor<Activity>()
                    let allActivities = try modelContext.fetch(descriptor)
                    for activity in allActivities {
                        modelContext.delete(activity) // histories cascade due to deleteRule: .cascade
                    }
                    //try modelContext.save()
                    
                    // Dismiss first to detach UI from deleted models
                    dismiss()
                    
                    // Notify and haptic on next runloop to avoid touching deleted objects in this view update
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .activityDidChange, object: nil)
                        let success = UINotificationFeedbackGenerator()
                        success.notificationOccurred(.success)
                    }
                } catch {
                    print("Failed to delete all Activities: \(error)")
                    let errorHaptic = UINotificationFeedbackGenerator()
                    errorHaptic.notificationOccurred(.error)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently remove ALL activities and their history. This action cannot be undone.")
        }
    }
    
    private func generateRandomHistories() {
        let cal = Calendar.current
        let now = Date()

        // Start of current month local
        let startOfCurrentMonth: Date = {
            let comps = cal.dateComponents([.year, .month], from: now)
            return cal.date(from: comps).map { cal.startOfDay(for: $0) } ?? cal.startOfDay(for: now)
        }()
        // Start of last month local
        let startOfLastMonth = cal.date(byAdding: .month, value: -1, to: startOfCurrentMonth) ?? startOfCurrentMonth
        // End boundary is start of next month (exclusive)
        let startOfNextMonth = cal.date(byAdding: .month, value: 1, to: startOfCurrentMonth) ?? startOfCurrentMonth

        func randomDateInRange() -> Date {
            let start = startOfLastMonth.timeIntervalSince1970
            let end = startOfNextMonth.timeIntervalSince1970
            guard end > start else { return startOfCurrentMonth }
            let random = Double.random(in: start..<end)
            return Date(timeIntervalSince1970: random)
        }

        for _ in 0..<30 {
            let randomDate = randomDateInRange()
            let entry = ActivityHistory(activity: activity, dateCompleted: randomDate)
            // Optionally also set recorded date to now
            entry.dateRecorded = now
            // Insert into model context
            modelContext.insert(entry)
        }
        try? modelContext.save()
        NotificationCenter.default.post(name: .activityDidChange, object: nil)
        let success = UINotificationFeedbackGenerator()
        success.notificationOccurred(.success)
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


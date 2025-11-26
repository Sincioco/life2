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
import Charts

// MARK: - ListView
struct ActivitiesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var Activities: [Activity]
    @Query(sort: [SortDescriptor(\Category.name, order: .forward)]) private var categories: [Category]
    
    @State private var isPresentingAddActivity = false
    @State private var searchText: String = ""
    @State private var showEmptyPrompt: Bool = true
    @State private var reloadID = UUID()
    @State private var pendingDelete: Activity? = nil
    @State private var isShowingDeleteAlert: Bool = false
    @State private var selectedCategory: String? = nil
    
    // Hard-refresh visual state
    @State private var isRefreshing: Bool = false
    @State private var refreshRotation: Double = 0
    
    private var filteredActivities: [Activity] {
        let base = Activities
        let categoryFiltered: [Activity]
        if let selected = selectedCategory, !selected.isEmpty {
            categoryFiltered = base.filter { $0.categoryName == selected }
        } else {
            categoryFiltered = base
        }
        guard !searchText.isEmpty else { return categoryFiltered }
        return categoryFiltered.filter { activity in
            activity.name.localizedCaseInsensitiveContains(searchText) ||
            activity.categoryName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var uniqueCategories: [String] {
        categories.map { $0.name }
    }
    
    private var groupedByCategory: [String: [Activity]] {
        Dictionary(grouping: filteredActivities, by: { $0.categoryName })
    }
    
    // Build a daily series for the current month: 1 if any activity in the category has a history on that day, else 0
    private func dailyDoneSeries(for category: String) -> [(date: Date, value: Int)] {
        let cal = Calendar.current
        let now = Date()
        // Start of current month
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
        let start = cal.startOfDay(for: startOfMonth)
        // Start of next month
        let nextMonth = cal.date(byAdding: .month, value: 1, to: start) ?? start
        let end = cal.startOfDay(for: nextMonth)
        
        // Collect all activities in this category from the currently filtered set (ignoring text filter to reflect raw category)
        let activitiesInCategory = Activities.filter { $0.categoryName == category }
        // Build a set of days (as startOfDay) where at least one history exists for the category
        var daysWithAny: Set<Date> = []
        for activity in activitiesInCategory {
            for history in activity.histories {
                if history.dateCompleted >= start && history.dateCompleted < end {
                    let sod = cal.startOfDay(for: history.dateCompleted)
                    daysWithAny.insert(sod)
                }
            }
        }
        
        // Create daily points from start to end-1 day
        var points: [(Date, Int)] = []
        var cursor = start
        while cursor < end {
            let value = daysWithAny.contains(cursor) ? 1 : 0
            points.append((cursor, value))
            cursor = cal.date(byAdding: .day, value: 1, to: cursor) ?? end
        }
        return points
    }
    
    var body: some View {
        NavigationStack {
            
            if Activities.isEmpty && showEmptyPrompt {
                VStack(spacing: 0) {
                    ContentUnavailableView(
                        "Welcome!  Let's get started!",
                        systemImage: "text.pad.header.badge.plus",
                        description: Text("You may add activities by tapping the + button above or I could create starter activities for you.  Which do you prefer?")
                    )
                    Button("Create Starter Activities") {
                        withAnimation {
                            Category.seedDefaultsIfNeeded(in: modelContext)
                            Activity.generateStarterActivities(in: modelContext)
                            showEmptyPrompt = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    Spacer()
                }
            }
            
            Group {
                VStack(spacing: 0) {
                    // Custom animated "hard refresh" banner
//                    if isRefreshing {
//                        HStack(spacing: 8) {
//                            Image(systemName: "arrow.clockwise.circle.fill")
//                                .symbolRenderingMode(.hierarchical)
//                                .font(.title3)
//                                .rotationEffect(.degrees(refreshRotation))
//                            
//                            VStack(alignment: .leading, spacing: 2) {
//                                Text("Refreshing activities")
//                                    .font(.caption)
//                                    .fontWeight(.semibold)
//                                    .textCase(.uppercase)
//                                Text("Pull-to-refresh triggered a hard data reload.")
//                                    .font(.caption2)
//                                    .foregroundStyle(.secondary)
//                            }
//                            
//                            Spacer(minLength: 0)
//                        }
//                        .padding(.horizontal, 12)
//                        .padding(.vertical, 8)
//                        .frame(maxWidth: .infinity)
//                        .background(.thinMaterial)
//                        .overlay(
//                            Divider()
//                                .offset(y: 12),
//                            alignment: .bottom
//                        )
//                        .transition(.move(edge: .top).combined(with: .opacity))
//                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isRefreshing)
//                    }
                    
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
                                            //let isDisabled = activity.count >= activity.maxCount
                                            Button {
                                                //if activity.count < activity.maxCount {
                                                    activity.increment(in: modelContext)
                                                    NotificationCenter.default.post(name: .activityDidChange, object: nil)
                                                    let success = UINotificationFeedbackGenerator()
                                                    success.notificationOccurred(.success)
//                                                } else {
//                                                    let warning = UINotificationFeedbackGenerator()
//                                                    warning.notificationOccurred(.warning)
//                                                }
                                            } label: {
                                                Label("Done", systemImage: "checkmark")
                                            }
                                            .tint(.green)
                                            //.disabled(isDisabled)
                                            
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
                            .listRowSeparator(.hidden)
                            .contentShape(Rectangle())
                        }
                    }
                    .id(reloadID)
                }
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
                .onChange(of: Activities.count) { oldValue, newValue in
                    if newValue == 0 { showEmptyPrompt = true }
                }
                .onReceive(NotificationCenter.default.publisher(for: .activityDidChange)) { _ in
                    reloadID = UUID()
                }
                // Pull-to-refresh: hard refresh of the activities list
                .refreshable {
                    await hardRefresh()
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
        // Spin animation driver for the refresh icon
        .onChange(of: isRefreshing) { _, newValue in
            if newValue {
                refreshRotation = 0
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                    refreshRotation = 360
                }
            } else {
                refreshRotation = 0
            }
        }
    }
    
    // MARK: - Hard refresh logic
    
    private func hardRefresh() async {
        await MainActor.run {
            withAnimation {
                isRefreshing = true
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        
        // Give SwiftData + @Query a moment & simulate a true "hard" reload
        try? await Task.sleep(nanoseconds: 700_000_000) // ~0.7s
        await MainActor.run {
            reloadID = UUID() // forces the List to rebuild
            NotificationCenter.default.post(name: .activityDidChange, object: nil)
        }
        try? await Task.sleep(nanoseconds: 400_000_000) // let the banner be visible
        
        await MainActor.run {
            withAnimation {
                isRefreshing = false
            }
        }
    }
    
    private func increment(_ activity: Activity) {
        activity.increment(in: modelContext)
        NotificationCenter.default.post(name: .activityDidChange, object: nil)
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let activityDidChange = Notification.Name("activityDidChange")
}

// MARK: - Preview code for Canvas
#Preview {
    let previewContainer: ModelContainer = {
        let schema = Schema([Activity.self, ActivityHistory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        
        let container = try! ModelContainer(for: schema, configurations: config)
        
        return container
    }()
    
    ActivitiesView()
        .modelContainer(previewContainer)
}

// ————————————————————————————————————————————————————————————————————————————————————————————————————
//                                   Life 2.0 - Activity History View
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Programmed By:  Louiery R. Sincioco                                                     Version: 1.0
// Programmed Date:  November 23, 2025                                                      For: iOS 26
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Purpose:  A model to keep track of completed activities.
// ————————————————————————————————————————————————————————————————————————————————————————————————————

import SwiftUI
import SwiftData

struct ActivityHistoryView: View {
    
    // Access to the SwiftData model context
    @Environment(\.modelContext) private var modelContext
    
    // Fetch all history records, newest at the top
    @Query(
        sort: [
            SortDescriptor(\ActivityHistory.dateCompleted, order: .reverse)
        ]
    )
    private var histories: [ActivityHistory]
    
    // MARK: - Deletion State
    
    @State private var historyToDelete: ActivityHistory?
    @State private var showDeleteConfirm = false
    @State private var showClearAllConfirm = false
    @State private var showGenerateConfirm = false
    
    var body: some View {
        NavigationStack {
            Group {
                if histories.isEmpty {
                    ContentUnavailableView(
                        "No Activity History",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Completed activities will appear here.")
                    )
                } else {
                    List {
                        ForEach(histories) { history in
                            HistoryRow(history: history)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        historyToDelete = history
                                        showDeleteConfirm = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Activity History")
//            .toolbar {
//                ToolbarItem(placement: .automatic) {
//                    Button("Generate Random") {
//                        showGenerateConfirm = true
//                    }
//                }
//                ToolbarSpacer()
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button("Clear All") {
//                        showClearAllConfirm = true
//                    }
//                }
//            }
//            // Confirm single delete
//            .alert(
//                "Delete this history entry?",
//                isPresented: $showDeleteConfirm,
//                presenting: historyToDelete
//            ) { history in
//                Button("Delete", role: .destructive) {
//                    performDelete(history)
//                }
//                Button("Cancel", role: .cancel) {
//                    historyToDelete = nil
//                }
//            } message: { _ in
//                Text("This action cannot be undone.")
//            }
//            // Confirm clear all
//            .alert("Clear all activity history?",
//                   isPresented: $showClearAllConfirm) {
//                Button("Clear All", role: .destructive) {
//                    performClearAll()
//                }
//                Button("Cancel", role: .cancel) { }
//            } message: {
//                Text("This will permanently remove all activity history entries.")
//            }
//            .alert("Generate random history for this month?", isPresented: $showGenerateConfirm) {
//                Button("Generate", role: .destructive) {
//                    Activity.generateRandomHistoricalActivities(in: modelContext)
//                    let success = UINotificationFeedbackGenerator()
//                    success.notificationOccurred(.success)
//                }
//                Button("Cancel", role: .cancel) { }
//            } message: {
//                Text("This will insert random history entries for all activities in the current month.")
//            }
        }
    }
    
    // MARK: - Actions called from alerts

    private func performClearAll() {
        do {
            let descriptor = FetchDescriptor<ActivityHistory>()
            let allHistories = try modelContext.fetch(descriptor)

            for history in allHistories {
                modelContext.delete(history)
            }

            try modelContext.save()

            // Notify ActivitiesView to refresh
            NotificationCenter.default.post(name: .activityDidChange, object: nil)
        } catch {
            print("Failed to clear ActivityHistory: \(error)")
        }
    }

    private func performDelete(_ history: ActivityHistory) {
        modelContext.delete(history)

        do {
            try modelContext.save()

            // Notify ActivitiesView to refresh
            NotificationCenter.default.post(name: .activityDidChange, object: nil)
        } catch {
            print("Failed to delete ActivityHistory: \(error)")
        }

        historyToDelete = nil
    }
}

// MARK: - Row View

private struct HistoryRow: View {
    
    let history: ActivityHistory
    
    private var activityName: String {
        history.activity?.name ?? "Unknown Activity"
    }
    
    private var iconName: String {
        history.activity?.icon ?? "questionmark.circle"
    }
    
    private var recurrenceText: String {
        if let recurrence = history.activity?.recurrence {
            return recurrence.rawValue
        } else {
            return "No Recurrence"
        }
    }
    
    private var completedDateText: String {
        formattedDate(history.dateCompleted, includeTime: true)
    }
    
    private var recordedDateText: String {
        formattedDate(history.dateRecorded, includeTime: true)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
//            Image(systemName: iconName)
            let icon = iconName
            let isAsset = UIImage(named: icon) != nil     // detect if image exists in Assets
            let img = isAsset ? Image(icon) : Image(systemName: icon)
        
            img
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundStyle(history.activity?.color.colorValue ?? .gray)
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                // Activity name & recurrence
                HStack {
                    Text(activityName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(recurrenceText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Completed date
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text("Completed:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(completedDateText)
                        .font(.caption)
                }
                
                // Recorded date
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Recorded:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(recordedDateText)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helpers
    
    private func formattedDate(_ date: Date, includeTime: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = includeTime ? .short : .none
        return formatter.string(from: date)
    }
}



// MARK: - Preview

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Activity.self,
            ActivityHistory.self,
            configurations: config
        )
        
        let context = container.mainContext
        
        // Sample activity
        let sampleActivity = Activity(
            name: "Sample Run",
            icon: "figure.run",
            recurrence: .daily,
            category: "Fitness",
            notes: "Morning jog around the park"
        )
        
        context.insert(sampleActivity)
        
        // Sample history entries
        let history1 = ActivityHistory(
            activity: sampleActivity,
            dateCompleted: .now.addingTimeInterval(-3600 * 5)
        )
        let history2 = ActivityHistory(
            activity: sampleActivity,
            dateCompleted: .now.addingTimeInterval(-3600 * 2)
        )
        
        context.insert(history1)
        context.insert(history2)
        
        return ActivityHistoryView()
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \\(error.localizedDescription)")
    }
}


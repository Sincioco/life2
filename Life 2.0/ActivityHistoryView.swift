// ————————————————————————————————————————————————————————————————————————————————————————————————————
//                               Life 2.0 - Activity History View
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Purpose: Displays a list of ActivityHistory records (most recent first).
// ————————————————————————————————————————————————————————————————————————————————————————————————————

import SwiftUI
import SwiftData

struct ActivityHistoryView: View {
    
    // Access to the SwiftData model context
    @Environment(\.modelContext) private var modelContext
    
    // Fetch all history records, newest at the top
    @Query(
        sort: [
            // Primary sort: dateCompleted (newest first)
            SortDescriptor(\ActivityHistory.dateCompleted, order: .reverse),
            // Secondary sort: dateRecorded (newest first) as a tie-breaker
            SortDescriptor(\ActivityHistory.dateRecorded, order: .reverse)
        ]
    )
    private var histories: [ActivityHistory]
    
    var body: some View {
        NavigationStack {
            Group {
                if histories.isEmpty {
                    ContentUnavailableView(
                        "No Activity History",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("History entries will appear here whenever an activity is completed.")
                    )
                } else {
                    List {
                        ForEach(histories) { history in
                            ActivityHistoryRow(history: history)
                        }
                        .onDelete(perform: deleteHistory)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Activity History")
            .toolbar {
                if !histories.isEmpty {
                    EditButton()
                }
            }
        }
    }
    
    // MARK: - Delete
    
    private func deleteHistory(at offsets: IndexSet) {
        for index in offsets {
            let history = histories[index]
            modelContext.delete(history)
        }
        // No need to manually save; SwiftData will handle changes as appropriate.
    }
}

private struct ActivityHistoryRow: View {
    
    let history: ActivityHistory
    
    // Safely unwrap any associated Activity (might be nil if the parent was deleted)
    private var activityName: String {
        if let activity = history.activity {
            return activity.name
        } else if !history.name.isEmpty {
            return history.name
        } else {
            return "Unknown Activity"
        }
    }
    
    private var iconName: String {
        if let activity = history.activity {
            return activity.icon
        } else if !history.icon.isEmpty {
            return history.icon
        } else {
            return "checkmark.circle"
        }
    }
    
    private var formattedCompletedDate: String {
        history.dateCompleted.formatted(date: .abbreviated, time: .shortened)
    }
    
    private var formattedRecordedDate: String {
        history.dateRecorded.formatted(date: .abbreviated, time: .shortened)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            
            // Icon
            Image(systemName: iconName)
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 26))
                .foregroundStyle(.blue)
                .frame(width: 36, height: 36)
            
            // Main content
            VStack(alignment: .leading, spacing: 4) {
                
                // Activity name + category
                HStack {
                    Text(activityName)
                        .font(.headline)
                    if !history.category.isEmpty {
                        Text(history.category)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Counts, recurrence
                HStack(spacing: 12) {
                    if history.maxCount > 0 {
                        Text("Count: \(history.count)/\(history.maxCount)")
                    } else {
                        Text("Count: \(history.count)")
                    }
                    
                    if !history.recurrence.isEmpty {
                        Text(history.recurrence)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                
                // Notes
                if !history.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(history.notes)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                
                // Dates
                HStack(spacing: 12) {
                    Label(formattedCompletedDate, systemImage: "checkmark.seal")
                    Label(formattedRecordedDate, systemImage: "tray.and.arrow.down")
                }
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}

// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Preview
// ————————————————————————————————————————————————————————————————————————————————————————————————————

#Preview {
    do {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Activity.self, ActivityHistory.self, configurations: configuration)
        
        // Create a couple of sample activities and history entries for the preview
        let context = container.mainContext
        
        let sampleActivity = Activity(
            name: "Sample Run",
            icon: "figure.run",
            count: 3,
            maxCount: 5,
            recurrence: "Daily",
            category: "Fitness",
            notes: "Example preview activity.",
            dateCreated: .now.addingTimeInterval(-86400 * 3),
            dateModified: .now
        )
        
        context.insert(sampleActivity)
        
        // Sample history entries
        let history1 = ActivityHistory(activity: sampleActivity, dateCompleted: .now.addingTimeInterval(-3600 * 5))
        let history2 = ActivityHistory(activity: sampleActivity, dateCompleted: .now.addingTimeInterval(-3600 * 2))
        
        context.insert(history1)
        context.insert(history2)
        
        return ActivityHistoryView()
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}

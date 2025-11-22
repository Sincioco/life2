
// ————————————————————————————————————————————————————————————————————————————————————————————————————
//                               Life 2.0 - Activity History View
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Purpose: Displays a list of ActivityHistory records (most recent first) and
//          is updated to match the new Activity / ActivityHistory models.
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
                                        delete(history)
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
        }
    }

    // MARK: - Delete

    private func delete(_ history: ActivityHistory) {
        modelContext.delete(history)

        do {
            try modelContext.save()
        } catch {
            // In a real app you might show an alert; for now we just log
            print("Failed to delete ActivityHistory: \\(error)")
        }
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
            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundStyle(.blue)
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

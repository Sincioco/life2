import SwiftUI
import SwiftData
import UIKit

struct OptionsView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var showGenerateConfirm = false
    @State private var showDeleteAllActivitiesConfirm = false
    @State private var showDeleteAllHistoryConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section("Debugging Tools") {
                    Button {
                        showGenerateConfirm = true
                    } label: {
                        Label("Generate Random Histories", systemImage: "sparkles")
                    }

                    Button(role: .destructive) {
                        showDeleteAllActivitiesConfirm = true
                    } label: {
                        Label("Delete All Activities", systemImage: "trash")
                    }

                    Button(role: .destructive) {
                        showDeleteAllHistoryConfirm = true
                    } label: {
                        Label("Delete All History", systemImage: "calendar")
                    }
                }
            }
            .navigationTitle("Options")
            // Alerts
            .alert("Generate random history for this month?", isPresented: $showGenerateConfirm) {
                Button("Generate", role: .destructive) {
                    Activity.generateRandomHistoricalActivities(in: modelContext)
                    NotificationCenter.default.post(name: .activityDidChange, object: nil)
                    let success = UINotificationFeedbackGenerator()
                    success.notificationOccurred(.success)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will insert random history entries for all activities in the current month.")
            }
            .alert("Delete ALL activities and their history?", isPresented: $showDeleteAllActivitiesConfirm) {
                Button("Delete All", role: .destructive) {
                    deleteAllActivities()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently remove all activities and their associated history. This action cannot be undone.")
            }
            .alert("Delete ALL activity history?", isPresented: $showDeleteAllHistoryConfirm) {
                Button("Delete All", role: .destructive) {
                    deleteAllHistory()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently remove all history entries for all activities. This action cannot be undone.")
            }
        }
    }

    // MARK: - Actions

    private func deleteAllActivities() {
        do {
            let descriptor = FetchDescriptor<Activity>()
            let allActivities = try modelContext.fetch(descriptor)
            for activity in allActivities {
                modelContext.delete(activity) // histories cascade due to deleteRule: .cascade
            }
            //try modelContext.save()
            NotificationCenter.default.post(name: .activityDidChange, object: nil)
            let success = UINotificationFeedbackGenerator()
            success.notificationOccurred(.success)
        } catch {
            print("Failed to delete all Activities: \(error)")
            let error = UINotificationFeedbackGenerator()
            error.notificationOccurred(.error)
        }
    }

    private func deleteAllHistory() {
        do {
            let descriptor = FetchDescriptor<ActivityHistory>()
            let allHistories = try modelContext.fetch(descriptor)
            for history in allHistories {
                modelContext.delete(history)
            }
            try modelContext.save()
            NotificationCenter.default.post(name: .activityDidChange, object: nil)
            let success = UINotificationFeedbackGenerator()
            success.notificationOccurred(.success)
        } catch {
            print("Failed to clear ActivityHistory: \(error)")
            let error = UINotificationFeedbackGenerator()
            error.notificationOccurred(.error)
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Activity.self,
            ActivityHistory.self,
            configurations: config
        )
        return OptionsView()
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \\(error.localizedDescription)")
    }
}

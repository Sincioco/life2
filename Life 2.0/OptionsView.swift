// ————————————————————————————————————————————————————————————————————————————————————————————————————
//                                         Life 2.0 - Options View
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Programmed By:  Louiery R. Sincioco                                                     Version: 1.0
// Programmed Date:  November 25, 2025                                                      For: iOS 26
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Purpose:  Setup the main Tab view of the application.
// ————————————————————————————————————————————————————————————————————————————————————————————————————
import SwiftUI
import SwiftData
import UIKit

struct OptionsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var activities: [Activity]
    
    @State private var showGenerateConfirm = false
    @State private var showDeleteAllActivitiesConfirm = false
    @State private var showDeleteAllHistoryConfirm = false
    
    @State private var showGenerateForActivitySheet = false
    @State private var selectedActivity: Activity? = nil
    @State private var showGenerateForActivityConfirm = false
    
    @State private var showDeleteForActivitySheet = false
    @State private var selectedActivityToDelete: Activity? = nil
    @State private var showDeleteForActivityConfirm = false
    
    @AppStorage("showMonthHistogram") private var showMonthHistogram: Bool = true
    @AppStorage("useRealisticIcons") private var useRealisticIcons: Bool = true
    @AppStorage("animateActivityBars") private var animateActivityBars: Bool = true
    @AppStorage("useActivityColorForBar") private var useActivityColorForBar: Bool = true
    @AppStorage("showAdjacentMonthIcons") private var showAdjacentMonthIcons: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Preferences") {
                    Toggle(isOn: $showMonthHistogram) {
                        Label("In Activities View, show Month Histogram for each row.", systemImage: "chart.xyaxis.line")
                    }
                    Toggle(isOn: $animateActivityBars) {      // NEW
                        Label("In Activities View, enable Activity Bar Animation.", systemImage: "waveform.path.ecg")
                    }
                    Toggle(isOn: $useActivityColorForBar) {
                        Label("In Activities View, use the Activity Color to fill the Gauge", systemImage: "paintpalette")
                    }
                    Toggle(isOn: $showAdjacentMonthIcons) {
                        Label("In Calendar View, show adjacent month Icons.", systemImage: "calendar.badge.plus")
                    }
                    Toggle(isOn: $useRealisticIcons) {
                        Label("Use realistic icons if available.", systemImage: "photo")
                    }
                }
                Section("Developer Tools for Testing and Debugging") {
                    Button {
                        selectedActivity = activities.first
                        showGenerateForActivitySheet = true
                    } label: {
                        Label("Generate History for an Activity", systemImage: "wand.and.stars")
                    }
                    
                    Button(role: .destructive) {
                        selectedActivityToDelete = activities.first
                        showDeleteForActivitySheet = true
                    } label: {
                        Label("Delete History for an Activity", systemImage: "trash.slash")
                    }
                    
                    Button(role: .destructive) {
                        showDeleteAllActivitiesConfirm = true
                    } label: {
                        Label("Delete All Activities", systemImage: "trash")
                    }
                    
                    Button {
                        showGenerateConfirm = true
                    } label: {
                        Label("Generate Random Histories for all Activities", systemImage: "sparkles")
                    }
                    
                    Button(role: .destructive) {
                        showDeleteAllHistoryConfirm = true
                    } label: {
                        Label("Delete All History", systemImage: "calendar")
                    }
                }
            }
            .navigationTitle("Options")
            // ... rest of file unchanged ...
            
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
            .sheet(isPresented: $showGenerateForActivitySheet) {
                NavigationStack {
                    Form {
                        Section("Select Activity") {
                            Picker("Activity", selection: $selectedActivity) {
                                ForEach(activities) { act in
                                    Text(act.name).tag(Optional(act))
                                }
                            }
                        }
                    }
                    .navigationTitle("Choose Activity")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showGenerateForActivitySheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Next") {
                                showGenerateForActivitySheet = false
                                // Defer to avoid alert conflict with sheet dismissal
                                DispatchQueue.main.async {
                                    showGenerateForActivityConfirm = true
                                }
                            }
                        }
                    }
                    .onAppear {
                        if selectedActivity == nil { selectedActivity = activities.first }
                    }
                }
            }
            .sheet(isPresented: $showDeleteForActivitySheet) {
                NavigationStack {
                    Form {
                        Section("Select Activity") {
                            Picker("Activity", selection: $selectedActivityToDelete) {
                                ForEach(activities) { act in
                                    Text(act.name).tag(Optional(act))
                                }
                            }
                        }
                    }
                    .navigationTitle("Choose Activity")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showDeleteForActivitySheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Next") {
                                showDeleteForActivitySheet = false
                                DispatchQueue.main.async {
                                    showDeleteForActivityConfirm = true
                                }
                            }
                        }
                    }
                    .onAppear {
                        if selectedActivityToDelete == nil { selectedActivityToDelete = activities.first }
                    }
                }
            }
            .alert("Generate random history for this activity?", isPresented: $showGenerateForActivityConfirm) {
                Button("Generate", role: .destructive) {
                    if let act = selectedActivity { generateRandomHistories(for: act) }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will insert random history entries for the selected activity across the last and current month.")
            }
            .alert("Delete ALL history for this activity?", isPresented: $showDeleteForActivityConfirm) {
                Button("Delete", role: .destructive) {
                    if let act = selectedActivityToDelete { deleteHistory(for: act) }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently remove all history entries for the selected activity. This action cannot be undone.")
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
    
    private func deleteHistory(for activity: Activity) {
        do {
            let descriptor = FetchDescriptor<ActivityHistory>()
            let allHistories = try modelContext.fetch(descriptor)
            for history in allHistories where history.activity == activity {
                modelContext.delete(history)
            }
            try modelContext.save()
            NotificationCenter.default.post(name: .activityDidChange, object: nil)
            let success = UINotificationFeedbackGenerator()
            success.notificationOccurred(.success)
        } catch {
            print("Failed to delete history for activity: \(error)")
            let error = UINotificationFeedbackGenerator()
            error.notificationOccurred(.error)
        }
    }
    
    private func generateRandomHistories(for activity: Activity) {
        let cal = Calendar.current
        let now = Date()
        
        let startOfCurrentMonth: Date = {
            let comps = cal.dateComponents([.year, .month], from: now)
            return cal.date(from: comps).map { cal.startOfDay(for: $0) } ?? cal.startOfDay(for: now)
        }()
        let startOfLastMonth = cal.date(byAdding: .month, value: -1, to: startOfCurrentMonth) ?? startOfCurrentMonth
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
            entry.dateRecorded = now
            modelContext.insert(entry)
        }
        do {
            try modelContext.save()
            NotificationCenter.default.post(name: .activityDidChange, object: nil)
            let success = UINotificationFeedbackGenerator()
            success.notificationOccurred(.success)
        } catch {
            print("Failed to save generated histories: \(error)")
            let errorH = UINotificationFeedbackGenerator()
            errorH.notificationOccurred(.error)
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

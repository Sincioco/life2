import SwiftUI
import SwiftData
import UIKit

// MARK: - Edit Activity View
struct EditActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var activity: Activity

    private let categories = [
        "Bills",
        "Fitness",
        "Learning",
        "Maintenance",
        "Personal",
        "Work",
        "Others"
    ]

    private enum AddEditTab: String, CaseIterable, Identifiable {
        case activity = "Activity"
        case history = "History"
        var id: String { rawValue }
    }
    @State private var selectedTab: AddEditTab = .activity

    @State private var showDeleteAlert = false
    @State private var showDeleteAllAlert = false

    @State private var isPresentingAddHistory = false
    @State private var newHistoryDate: Date = Date()

    @State private var editingHistory: ActivityHistory? = nil
    @State private var editingHistoryDate: Date = Date()

    @State private var originalName: String = ""
    @State private var originalIcon: String = ""
    @State private var originalCategory: String = ""
    @State private var originalNotes: String = ""
    @State private var didSave: Bool = false

    @State private var isPresentingIconPicker = false
    @State private var isPresentingColorPicker = false
    
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
//                    Picker("Color", selection: $activity.color) {
//                        ForEach(ActivityColor.allCases, id: \.self) { color in
//                            HStack(spacing: 8) {
//                                Circle()
//                                    .frame(width: 16, height: 16)
//                                    .foregroundStyle(color.colorValue)
//                                Text(color.rawValue.capitalized)
//                            }
//                            .tag(color)
//                        }
//                    }
                    Button {
                            isPresentingColorPicker = true
                        } label: {
                            HStack {
                                Text("Color")
                                Spacer()
                                Circle()
                                    .fill(activity.color.colorValue)
                                    .frame(width: 16, height: 16)
                                Text(activity.color.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
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
                                    .foregroundStyle(activity.color.colorValue)
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
            }
        }
        .navigationTitle("Edit Activity")
        .navigationBarTitleDisplayMode(.inline)
                .toolbar {
            if selectedTab == .activity {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if activity.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return }
                        didSave = true
                        activity.dateModified = Date()
                        try? modelContext.save()
                        NotificationCenter.default.post(name: .activityDidChange, object: nil)
                        dismiss()
                    }
                    .disabled(activity.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        .sheet(isPresented: $isPresentingIconPicker) {
            NavigationStack {
                IconPickerView(selectedIcon: $activity.icon)
            }
        }
        .sheet(isPresented: $isPresentingColorPicker) {
            NavigationStack {
                VStack(alignment: .leading) {
                    Text("Choose Color")
                        .font(.headline)
                        .padding(.bottom, 8)

                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 16)], spacing: 16) {
                            ForEach(ActivityColor.allCases, id: \.self) { color in
                                Button {
                                    activity.color = color
                                    isPresentingColorPicker = false
                                } label: {
                                    VStack {
                                        Circle()
                                            .fill(color.colorValue)
                                            .frame(width: 32, height: 32)
                                        Text(color.rawValue.capitalized)
                                            .font(.caption2)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .alert("Delete Activity?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
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
                        modelContext.delete(activity)
                    }
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
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Activity.self,
            ActivityHistory.self,
            configurations: config
        )

        let context = container.mainContext

        // Sample activity for editing
        let sample = Activity(
            name: "Sample Run",
            icon: "figure.run",
            recurrence: .weekly,
            category: "Fitness",
            notes: "Edit preview"
        )
        context.insert(sample)

        // Add a couple of history entries
        let cal = Calendar.current
        let now = Date()
        for d in [0, -2] {
            if let date = cal.date(byAdding: .day, value: d, to: now) {
                let entry = ActivityHistory(activity: sample, dateCompleted: date)
                context.insert(entry)
            }
        }

        return EditActivityView(activity: sample)
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}

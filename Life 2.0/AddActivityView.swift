import SwiftUI
import SwiftData

// MARK: - Add Activity View
struct AddActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var activities: [Activity]

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
    @State private var recurrence: Recurrence = .weekly
    @State private var category: String = "Fitness"
    @State private var notes: String = ""

    // Focus management
    @FocusState private var isNameFocused: Bool

    // Computed progress based on count and maxCount
    private var computedProgress: Double {
        guard maxCount > 0 else { return 0 }
        let ratio = min(Double(count) / Double(maxCount), 1.0)
        return max(0, ratio) * 100
    }

    private var usedIconNames: Set<String> {
        Set(activities.map { $0.icon })
    }

    /// Picks a default icon that is not currently used by any existing Activity, if possible.
    /// Falls back to the current `icon` value if all candidates are taken.
    private func pickDefaultIcon() -> String {
        // Small set of reasonable default candidates; the icon picker will still
        // enforce uniqueness for the full symbol list.
        let candidates = [
            "figure.walk",
            "figure.run",
            "figure.strengthtraining.traditional",
            "bicycle",
            "flame.fill",
            "heart.fill",
            "star.fill",
            "house.fill",
            "pencil",
            "book",
            "briefcase.fill"
        ]

        for candidate in candidates {
            if !usedIconNames.contains(candidate) {
                return candidate
            }
        }

        // If everything above is already used, keep the existing default.
        return icon
    }


    var body: some View {
        NavigationStack {
            Form {
                Section("Activity") {
                    TextField("Name", text: $name)
                        .focused($isNameFocused)

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
//                            Text(icon)
//                                .font(.caption)
//                                .foregroundStyle(.secondary)
//                                .lineLimit(1)
//                                .truncationMode(.middle)
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
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveActivity() }
                }
            }
            .onAppear {
                // Choose a default icon that has not yet been used by any Activity, if possible
                icon = pickDefaultIcon()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isNameFocused = true
                }
            }
            .sheet(isPresented: $isPresentingIconPicker) {
                NavigationStack {
                    IconPickerView(selectedIcon: $icon)
                }
            }
        }
    }

    // Save a new Activity to SwiftData
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

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Activity.self,
            ActivityHistory.self,
            configurations: config
        )
        return AddActivityView()
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}

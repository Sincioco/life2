import SwiftUI
import SwiftData

// MARK: - Add Activity View
struct AddActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("useRealisticIcons") private var useRealisticIcons: Bool = true

    @Query private var activities: [Activity]
    @Query(sort: [SortDescriptor(\Category.name, order: .forward)]) private var categories: [Category]

    private let recurrencies = Recurrence.allCases

    // Sheet state
    @State private var isPresentingIconPicker = false

    // Form fields
    @State private var name: String = ""
    @State private var icon: String = "figure.walk"
    @State private var count: Int = 0
    @State private var maxCount: Int = 7
    @State private var recurrence: Recurrence = .weekly
    @State private var categoryName: String = ""
    @State private var notes: String = ""
    @State private var color: ActivityColor = .blue
    @State private var isPresentingColorPicker: Bool = false
    @State private var showIconInUseAlert: Bool = false


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

    /// Returns a small list of recommended SF Symbols based on the selected category.
    /// Filters out icons that are already used by other activities.
    private func recommendedIcons(for categoryName: String) -> [String] {
        let base: [String]
        switch categoryName {
        case "Fitness":
            base = [
                "figure.walk",
                "figure.run",
                "figure.strengthtraining.traditional",
                "bicycle",
                "flame.fill",
                "heart.fill",
                "sportscourt.fill",
                "dumbbell.fill"
            ]
        case "Bills":
            base = [
                "creditcard",
                "creditcard.fill",
                "dollarsign.circle",
                "dollarsign.circle.fill",
                "list.bullet.rectangle"
            ]
        case "Learning":
            base = [
                "book",
                "book.fill",
                "graduationcap.fill",
                "brain.head.profile"
            ]
        case "Maintenance":
            base = [
                "wrench.and.screwdriver.fill",
                "gearshape.fill",
                "hammer.fill"
            ]
        case "Work":
            base = [
                "briefcase.fill",
                "laptopcomputer",
                "calendar.badge.clock"
            ]
        case "Personal":
            base = [
                "person.fill",
                "heart.text.square.fill",
                "face.smiling"
            ]
        case "Others":
            fallthrough
        default:
            base = [
                "star.fill",
                "sparkles",
                "square.and.pencil",
                "square.grid.2x2"
            ]
        }
        return base.filter { !usedIconNames.contains($0) }
    }

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
                            let assetExists = UIImage(named: icon) != nil
                            let img: Image = (useRealisticIcons && assetExists) ? Image(icon) : Image(systemName: icon)
                            img
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

                    if !color.rawValue.isEmpty {
                        HStack {
                            Text("Color")
                            Spacer()
                            Circle()
                                .fill(color.colorValue)
                                .frame(width: 16, height: 16)
                            Text(color.rawValue.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isPresentingColorPicker = true
                        }
                    }

                    let suggestions = recommendedIcons(for: categoryName)
                    if !suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recommended Icons")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(suggestions, id: \.self) { suggestion in
                                        Button {
                                            icon = suggestion
                                        } label: {
                                            HStack(spacing: 4) {
                                                let assetExists = UIImage(named: suggestion) != nil
                                                let img: Image = (useRealisticIcons && assetExists) ? Image(suggestion) : Image(systemName: suggestion)
                                                img
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 16, height: 16)
                                                Text(suggestion)
                                                    .font(.caption2)
                                                    .lineLimit(1)
                                                    .truncationMode(.middle)
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color(.secondarySystemBackground))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.top, 4)
                    }

                    Picker("Category", selection: $categoryName) {
                        ForEach(categories) { cat in
                            Text(cat.name).tag(cat.name)
                        }
                    }

                    Picker("Goal", selection: $recurrence) {
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
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                // Choose a default icon that has not yet been used by any Activity, if possible
                icon = pickDefaultIcon()
                if categoryName.isEmpty {
                    categoryName = categories.first?.name ?? ""
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isNameFocused = true
                }
            }
            .sheet(isPresented: $isPresentingIconPicker) {
                NavigationStack {
                    IconPickerView(selectedIcon: $icon)
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
                                ForEach(ActivityColor.allCases, id: \.self) { colorOption in
                                    Button {
                                        color = colorOption
                                        isPresentingColorPicker = false
                                    } label: {
                                        VStack {
                                            Circle()
                                                .fill(colorOption.colorValue)
                                                .frame(width: 32, height: 32)
                                            Text(colorOption.rawValue.capitalized)
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
        }
        .alert("Icon already in use", isPresented: $showIconInUseAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This icon is already used by another activity. Please choose a different icon.")
        }
    }

    // Save a new Activity to SwiftData
    private func saveActivity() {
        // Validate required name
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        // Enforce icon uniqueness at the Add level as a safety net,
        // in case an icon somehow slips through the picker filtering.
        if usedIconNames.contains(icon) {
            showIconInUseAlert = true
            return
        }

        let now = Date()
        let newActivity = Activity(
            name: name,
            icon: icon,
            recurrence: recurrence,
            categoryName: categoryName,
            notes: notes,
            color: color,
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


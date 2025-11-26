import SwiftUI
import SwiftData
import UIKit

struct CategoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Category.name, order: .forward)]) private var categories: [Category]

    @State private var isPresentingAdd: Bool = false
    @State private var newName: String = ""
    @State private var newIcon: String = "figure.run"
    @State private var newColor: ActivityColor = .green
    @State private var isPresentingIconPicker: Bool = false
    @AppStorage("useRealisticIcons") private var useRealisticIcons: Bool = true

    private var usedCategoryNames: Set<String> { Set(categories.map { $0.name }) }
    private var usedCategoryColors: Set<ActivityColor> { Set(categories.map { $0.color }) }

    var body: some View {
        NavigationStack {
            Group {
                if categories.isEmpty {
                    ContentUnavailableView(
                        "No Categories",
                        systemImage: "folder",
                        description: Text("Create or edit categories for your activities.")
                    )
                } else {
                    List {
                        ForEach(categories) { category in
                            NavigationLink {
                                EditCategoryView(category: category)
                            } label: {
                                HStack(spacing: 12) {
                                    let icon = category.icon
                                    let assetExists = UIImage(named: icon) != nil
                                    let img: Image = (useRealisticIcons && assetExists) ? Image(icon) : Image(systemName: icon)
                                    img
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .foregroundStyle(category.color.colorValue)
                                    Text(category.name)
                                        .font(.body)
                                }
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                Category.seedDefaultsIfNeeded(in: modelContext)
            }
            .sheet(isPresented: $isPresentingAdd) {
                NavigationStack {
                    Form {
                        Section("New Category") {
                            TextField("Name", text: $newName)
                            HStack {
                                Text("Icon")
                                Spacer()
                                let assetExists = UIImage(named: newIcon) != nil
                                let img: Image = (useRealisticIcons && assetExists) ? Image(newIcon) : Image(systemName: newIcon)
                                img
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                Text(newIcon)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { isPresentingIconPicker = true }
                            TextField("Symbol name", text: $newIcon)
                            Picker("Color", selection: $newColor) {
                                ForEach(ActivityColor.allCases.filter { !usedCategoryColors.contains($0) }, id: \.self) { c in
                                    HStack(spacing: 8) {
                                        Circle().fill(c.colorValue).frame(width: 16, height: 16)
                                        Text(c.rawValue.capitalized)
                                    }.tag(c)
                                }
                            }
                        }
                    }
                    .navigationTitle("Add Category")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { isPresentingAdd = false } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                addCategory()
                            }
                            .disabled(
                                newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                usedCategoryNames.contains(newName.trimmingCharacters(in: .whitespacesAndNewlines)) ||
                                usedCategoryColors.contains(newColor)
                            )
                        }
                    }
                    .sheet(isPresented: $isPresentingIconPicker) {
                        NavigationStack {
                            IconPickerView(selectedIcon: $newIcon)
                        }
                    }
                }
            }
        }
    }

    private func addCategory() {
        let now = Date()
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !usedCategoryNames.contains(trimmed), !usedCategoryColors.contains(newColor) else { return }
        let cat = Category(name: trimmed, icon: newIcon, color: newColor, dateCreated: now, dateModified: now)
        modelContext.insert(cat)
        try? modelContext.save()
        newName = ""
        newIcon = "figure.run"
        newColor = .green
        isPresentingAdd = false
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { modelContext.delete(categories[index]) }
        try? modelContext.save()
    }
}

struct EditCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var category: Category
    @AppStorage("useRealisticIcons") private var useRealisticIcons: Bool = true
    @State private var isPresentingIconPicker: Bool = false
    @Query(sort: [SortDescriptor(\Category.name)]) private var allCategories: [Category]

    private var usedColorsExcludingCurrent: Set<ActivityColor> { Set(allCategories.filter { $0.id != category.id }.map { $0.color }) }
    private var usedNamesExcludingCurrent: Set<String> { Set(allCategories.filter { $0.id != category.id }.map { $0.name }) }

    var body: some View {
        Form {
            Section("Category") {
                TextField("Name", text: $category.name)
                HStack {
                    Text("Icon")
                    Spacer()
                    let icon = category.icon
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
                }
                .contentShape(Rectangle())
                .onTapGesture { isPresentingIconPicker = true }
                TextField("Symbol name", text: $category.icon)
                Picker("Color", selection: $category.color) {
                    ForEach(ActivityColor.allCases.filter { !usedColorsExcludingCurrent.contains($0) }, id: \.self) { c in
                        HStack(spacing: 8) {
                            Circle().fill(c.colorValue).frame(width: 16, height: 16)
                            Text(c.rawValue.capitalized)
                        }.tag(c)
                    }
                }
            }
        }
        .navigationTitle("Edit Category")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    category.dateModified = Date()
                    try? modelContext.save()
                    dismiss()
                }
                .disabled(
                    category.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    usedNamesExcludingCurrent.contains(category.name.trimmingCharacters(in: .whitespacesAndNewlines))
                )
            }
        }
        .sheet(isPresented: $isPresentingIconPicker) {
            NavigationStack {
                IconPickerView(selectedIcon: $category.icon)
            }
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Activity.self, ActivityHistory.self, Category.self,
            configurations: config
        )
        return CategoryListView().modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}

import Foundation
import SwiftData
import SwiftUI

@Model
class Category {
    @Attribute(.unique) var name: String
    @Attribute(.unique) var icon: String
    var color: ActivityColor
    var dateCreated: Date
    var dateModified: Date

    init(name: String,
         icon: String,
         color: ActivityColor,
         dateCreated: Date = Date(),
         dateModified: Date = Date()) {
        self.name = name
        self.icon = icon
        self.color = color
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }
}

extension Category {
    static let defaultSeed: [(name: String, icon: String, color: ActivityColor)] = [
        ("Fitness", "figure.run", .blue),
        ("Fun", "basketball.fill", .yellow),
        ("Work", "calendar.badge.clock", .green)
    ]

    /// Seed defaults if there are no categories yet
    static func seedDefaultsIfNeeded(in context: ModelContext) {
        do {
            let count = try context.fetchCount(FetchDescriptor<Category>())
            guard count == 0 else { return }
            for item in defaultSeed {
                let cat = Category(name: item.name, icon: item.icon, color: item.color)
                context.insert(cat)
            }
            try context.save()
        } catch {
            print("Failed to seed default categories: \(error)")
        }
    }
}


// MARK: - Backup Export / Import (Category)
extension Category {
    struct CategoryBackup: Codable {
        let name: String
        let icon: String
        let color: ActivityColor
        let dateCreated: Date
        let dateModified: Date
    }

    static func exportAll(in context: ModelContext) throws -> [CategoryBackup] {
        let descriptor = FetchDescriptor<Category>()
        let all = try context.fetch(descriptor)
        return all.map { category in
            CategoryBackup(
                name: category.name,
                icon: category.icon,
                color: category.color,
                dateCreated: category.dateCreated,
                dateModified: category.dateModified
            )
        }
    }

    static func importAll(_ items: [CategoryBackup], in context: ModelContext) throws {
        for item in items {
            let category = Category(
                name: item.name,
                icon: item.icon,
                color: item.color,
                dateCreated: item.dateCreated,
                dateModified: item.dateModified
            )
            context.insert(category)
        }
        try context.save()
    }
}

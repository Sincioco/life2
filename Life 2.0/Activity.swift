
import Foundation
import SwiftData

enum Recurrence: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    case none = "None"
}

@Model
class Activity {
    var name: String
    var icon: String
    var recurrence: Recurrence
    var category: String
    var notes: String
    var dateCreated: Date
    var dateModified: Date

    @Relationship(deleteRule: .cascade, inverse: \ActivityHistory.activity)
    var histories: [ActivityHistory] = []

    /// Computed maxCount based on recurrence
    var maxCount: Int {
        switch recurrence {
        case .daily:   return 1
        case .weekly:  return 7
        case .monthly: return 31
        case .yearly:  return 366
        case .none:    return 0
        }
    }

    /// Count is now derived from history within the recurrence window
    var count: Int {
        historiesForCurrentRecurrence().count
    }

    /// Progress (0–100)
    var progress: Double {
        guard maxCount > 0 else { return 0 }
        return min(Double(count) / Double(maxCount), 1.0) * 100.0
    }

    init(
        name: String,
        icon: String,
        recurrence: Recurrence,
        category: String,
        notes: String,
        dateCreated: Date = Date(),
        dateModified: Date = Date()
    ) {
        self.name = name
        self.icon = icon
        self.recurrence = recurrence
        self.category = category
        self.notes = notes
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }
}

extension Activity {

    /// Filters history based on recurrence window
    func historiesForCurrentRecurrence(
        relativeTo now: Date = Date(),
        calendar baseCalendar: Calendar = .current
    ) -> [ActivityHistory] {

        var calendar = baseCalendar
        let all = histories

        switch recurrence {
        case .daily:
            return all.filter { calendar.isDate($0.dateCompleted, inSameDayAs: now) }

        case .weekly:
            calendar.firstWeekday = 2
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: now)
            else { return [] }
            return all.filter { interval.contains($0.dateCompleted) }

        case .monthly:
            guard let interval = calendar.dateInterval(of: .month, for: now)
            else { return [] }
            return all.filter { interval.contains($0.dateCompleted) }

        case .yearly:
            guard let interval = calendar.dateInterval(of: .year, for: now)
            else { return [] }
            return all.filter { interval.contains($0.dateCompleted) }

        case .none:
            return all
        }
    }

    /// Increment by one – directly inserts a history entry
    func increment(in context: ModelContext) {
        let now = Date()
        let entry = ActivityHistory(activity: self, dateCompleted: now)
        context.insert(entry)
        self.dateModified = now
    }

    /// Increment multiple times
    func increment(by amount: Int, in context: ModelContext) {
        guard amount > 0 else { return }
        let now = Date()
        for _ in 0..<amount {
            let entry = ActivityHistory(activity: self, dateCompleted: now)
            context.insert(entry)
        }
        self.dateModified = now
    }

    /// Adjust history to match a target count
    func setCount(_ newValue: Int, in context: ModelContext) {
        let target = max(0, newValue)
        let current = count

        if target > current {
            increment(by: target - current, in: context)
        } else if target < current {
            let diff = current - target
            let window = historiesForCurrentRecurrence()
                .sorted { $0.dateCompleted > $1.dateCompleted }

            for entry in window.prefix(diff) {
                context.delete(entry)
            }
        }

        self.dateModified = Date()
    }
}

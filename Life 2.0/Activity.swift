// ————————————————————————————————————————————————————————————————————————————————————————————————————
//                                         Life 2.0 - Main View
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Programmed By:  Louiery R. Sincioco                                                     Version: 1.0
// Programmed Date:  November 19, 2025                                                      For: iOS 26
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Purpose:  Setup the main Tab view of the application.
// ————————————————————————————————————————————————————————————————————————————————————————————————————

import Foundation
import SwiftData
import SwiftUI

enum Recurrence: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    case none = "None"
}

// Pure SwiftUI System Colors Only
enum ActivityColor: String, Codable, CaseIterable {
    case red, orange, yellow, green, mint, teal, cyan, blue
    case indigo, purple, pink, brown, gray, black, white
    
    var colorValue: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .mint: return .mint
        case .teal: return .teal
        case .cyan: return .cyan
        case .blue: return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink: return .pink
        case .brown: return .brown
        case .gray: return .gray
        case .black: return .black
        case .white: return .white
        }
    }
}

@Model
class Activity {
    @Attribute(.unique) var name: String
    @Attribute(.unique) var icon: String
    var recurrence: Recurrence
    var maxCount: Int
    var color: ActivityColor
    var categoryName: String
    var notes: String
    var dateCreated: Date
    var dateModified: Date
    
    @Relationship(deleteRule: .cascade, inverse: \ActivityHistory.activity)
    var histories: [ActivityHistory] = []
    
    /// Default max count mapping for a recurrence
    static func defaultMaxCount(for recurrence: Recurrence) -> Int {
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
        categoryName: String,
        notes: String,
        color: ActivityColor = .blue,
        maxCount: Int? = nil,
        dateCreated: Date = Date(),
        dateModified: Date = Date()
    ) {
        self.name = name
        self.icon = icon
        self.recurrence = recurrence
        self.categoryName = categoryName
        self.notes = notes
        self.maxCount = maxCount ?? Activity.defaultMaxCount(for: recurrence)
        self.color = color
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
    
    static func generateStarterActivities(in context: ModelContext) {
        
        let now = Date()
        
        // Randomize dates similar to the old commented code,
        // but now based on the Recurrence enum.
        func randomizedDate(for recurrence: Recurrence, now: Date) -> Date {
            let calendar = Calendar.current
            
            switch recurrence {
            case .daily:
                // Random hour within today
                let hours = Int.random(in: 0...23)
                return calendar.date(byAdding: .hour, value: -hours, to: now) ?? now
                
            case .weekly:
                // Random day within the last week
                let days = Int.random(in: 0...7)
                return calendar.date(byAdding: .day, value: -days, to: now) ?? now
                
            case .monthly:
                // Random day within roughly the last month
                let days = Int.random(in: 0...30)
                return calendar.date(byAdding: .day, value: -days, to: now) ?? now
                
            case .yearly:
                // Random day within roughly the last year
                let days = Int.random(in: 0...365)
                return calendar.date(byAdding: .day, value: -days, to: now) ?? now
                
            case .none:
                return now
            }
        }
        
        // Starter activities (categories taken from your categories array:
        // "Bills", "Fitness", "Learning", "Maintenance", "Personal", "Work", "Others")
        let starters: [Activity] = [
            Activity(
                name: "Morning Run",
                icon: "figure.run",
                recurrence: .weekly,
                categoryName: "Fitness",
                notes: "Easy-paced 20–30 minute run.",
                color: ActivityColor.blue,
                maxCount: Activity.defaultMaxCount(for: .weekly),
                dateCreated: randomizedDate(for: .weekly, now: now),
                dateModified: randomizedDate(for: .weekly, now: now)
            ),
            Activity(
                name: "Gym",
                icon: "dumbbell.fill",
                recurrence: .weekly,
                categoryName: "Fitness",
                notes: "Strength training at the gym.",
                color: ActivityColor.blue,
                maxCount: 4,
                dateCreated: randomizedDate(for: .weekly, now: now),
                dateModified: randomizedDate(for: .weekly, now: now)
            ),
            Activity(
                name: "Walk the Dog",
                icon: "dog.fill",
                recurrence: .daily,
                categoryName: "Fitness",
                notes: "Walk Max every day",
                color: ActivityColor.blue,
                maxCount: 7,
                dateCreated: randomizedDate(for: .daily, now: now),
                dateModified: randomizedDate(for: .daily, now: now)
            ),
            Activity(
                name: "Play Elden Ring",
                icon: "gamecontroller.fill",
                recurrence: .weekly,
                categoryName: "Fun",
                notes: "I'm stuck at the final boss",
                color: ActivityColor.yellow,
                maxCount: 3,
                dateCreated: randomizedDate(for: .weekly, now: now),
                dateModified: randomizedDate(for: .weekly, now: now)
            ),
            Activity(
                name: "Play Basketball",
                icon: "basketball.fill",
                recurrence: .weekly,
                categoryName: "Fun",
                notes: "Basketball just for fun",
                color: ActivityColor.yellow,
                maxCount: 2,
                dateCreated: randomizedDate(for: .weekly, now: now),
                dateModified: randomizedDate(for: .weekly, now: now)
            ),
            Activity(
                name: "Team Meeting",
                icon: "person.3.fill",
                recurrence: .weekly,
                categoryName: "Work",
                notes: "Morning Scrum.",
                color: ActivityColor.green,
                maxCount: 5,
                dateCreated: randomizedDate(for: .weekly, now: now),
                dateModified: randomizedDate(for: .weekly, now: now)
            ),
            Activity(
                name: "Weekly Planning",
                icon: "calendar.badge.clock",
                recurrence: .weekly,
                categoryName: "Work",
                notes: "Plan tasks and priorities for the week.",
                color: ActivityColor.green,
                maxCount: 1,
                dateCreated: randomizedDate(for: .weekly, now: now),
                dateModified: randomizedDate(for: .weekly, now: now)
            )
        ]
        
        // Insert into SwiftData
        for activity in starters {
            context.insert(activity)
        }
        
        do {
            try context.save()
        } catch {
            print("Error saving starter activities: \(error)")
        }
        
        // Let listeners (like ActivitiesView) know the data changed
        NotificationCenter.default.post(name: .activityDidChange, object: nil)
        
        //Activity.generateRandomHistoricalActivities(in: context)
    }
    
    static func generateRandomHistoricalActivities(in context: ModelContext) {
        
        let calendar = Calendar.current
        let now = Date()
        
        // Start date: two months ago (start of that day), up to and including today.
        guard let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: now) else {
            return
        }
        
        let startDate = calendar.startOfDay(for: twoMonthsAgo)
        let today = calendar.startOfDay(for: now)
        
        // Number of days between startDate and today (inclusive)
        let daysDiff = calendar.dateComponents([.day], from: startDate, to: today).day ?? 0
        if daysDiff < 0 { return }
        
        // Fetch all activities from the model context
        let activities: [Activity]
        do {
            activities = try context.fetch(FetchDescriptor<Activity>())
        } catch {
            print("Error fetching activities for history generation: \(error)")
            return
        }
        
        // For each existing activity, create random history entries between
        // two months ago and today inclusive. Ensure that no single day
        // has the same activity more than once.
        for activity in activities {
            
            // Build a set of existing days for this activity within the range
            var existingDays = Set<Date>()
            for history in activity.histories {
                let day = calendar.startOfDay(for: history.dateCompleted)
                if day >= startDate && day <= today {
                    existingDays.insert(day)
                }
            }
            
            // Iterate each day from startDate up to today
            for dayOffset in 0...daysDiff {
                guard let baseDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else {
                    continue
                }
                
                let dayKey = calendar.startOfDay(for: baseDate)
                // Skip if this activity already has an entry on this day
                if existingDays.contains(dayKey) { continue }
                
                // Randomly decide whether this activity occurs on this day (0 or 1 time)
                let shouldCreateEntry = Bool.random()
                if !shouldCreateEntry { continue }
                
                // Random time during that day (e.g. 0–23h, 0–59m, 0–59s)
                let hour = Int.random(in: 0..<24)
                let minute = Int.random(in: 0..<60)
                let second = Int.random(in: 0..<60)
                
                let randomDate = calendar.date(
                    bySettingHour: hour,
                    minute: minute,
                    second: second,
                    of: baseDate
                ) ?? baseDate
                
                let history = ActivityHistory(
                    activity: activity,
                    dateCompleted: randomDate
                )
                context.insert(history)
                existingDays.insert(dayKey)
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Error saving random historical activities: \(error)")
        }
        
        // Notify other views (calendar, lists, etc.) that data changed
        NotificationCenter.default.post(name: .activityDidChange, object: nil)
        
        
        
    }
    
    /// Convenience wrapper to generate random histories using the same
    /// rules as `generateRandomHistoricalActivities`:
    /// - Between two months ago and today (inclusive)
    /// - At most one history per activity per day
    static func generateRandomHistories(in context: ModelContext) {
        generateRandomHistoricalActivities(in: context)
    }
}



// MARK: - Backup Export / Import (Activity)
extension Activity {
    struct ActivityBackup: Codable {
        let name: String
        let icon: String
        let recurrence: Recurrence
        let maxCount: Int
        let color: ActivityColor
        let categoryName: String
        let notes: String
        let dateCreated: Date
        let dateModified: Date
    }

    static func exportAll(in context: ModelContext) throws -> [ActivityBackup] {
        let descriptor = FetchDescriptor<Activity>()
        let all = try context.fetch(descriptor)
        return all.map { activity in
            ActivityBackup(
                name: activity.name,
                icon: activity.icon,
                recurrence: activity.recurrence,
                maxCount: activity.maxCount,
                color: activity.color,
                categoryName: activity.categoryName,
                notes: activity.notes,
                dateCreated: activity.dateCreated,
                dateModified: activity.dateModified
            )
        }
    }

    static func importAll(_ items: [ActivityBackup], in context: ModelContext) throws {
        for item in items {
            let activity = Activity(
                name: item.name,
                icon: item.icon,
                recurrence: item.recurrence,
                categoryName: item.categoryName,
                notes: item.notes,
                color: item.color,
                maxCount: item.maxCount,
                dateCreated: item.dateCreated,
                dateModified: item.dateModified
            )
            context.insert(activity)
        }
        try context.save()
    }
}

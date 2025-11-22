// ————————————————————————————————————————————————————————————————————————————————————————————————————
//                                Life 2.0 - Activity History Data Model
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Programmed By:  Louiery R. Sincioco                                                     Version: 1.0
// Programmed Date:  November 23, 2025                                                      For: iOS 26
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Purpose:  Defines the Activity History Data Model.
// ————————————————————————————————————————————————————————————————————————————————————————————————————

import Foundation
import SwiftData

@Model
class ActivityHistory {
    // If Activity defines a back-reference (e.g., `@Relationship var histories: [Activity_History]`),
    // set the inverse like: `@Relationship(deleteRule: .nullify, inverse: \Activity.histories)`
    //@Relationship(deleteRule: .nullify) var activity: Activity?
    @Relationship var activity: Activity?

    // Snapshot fields
    var name: String
    var icon: String
    var count: Int
    var maxCount: Int
    var recurrence: String
    var category: String
    var notes: String

    // When this completion was recorded
    var dateCompleted: Date
    // Bookkeeping
    var dateRecorded: Date

    init(activity: Activity?, dateCompleted: Date = Date()) {
        self.activity = activity
        self.name = activity?.name ?? ""
        self.icon = activity?.icon ?? ""
        self.count = activity?.count ?? 0
        self.maxCount = activity?.maxCount ?? 0
        self.recurrence = activity?.recurrence ?? ""
        self.category = activity?.category ?? ""
        self.notes = activity?.notes ?? ""
        self.dateCompleted = dateCompleted
        self.dateRecorded = Date()
    }
}

extension Activity {
    // Helper to append a history entry when this activity is completed
    func recordCompletion(on date: Date = Date(), in context: ModelContext) {
        let entry = ActivityHistory(activity: self, dateCompleted: date)
        context.insert(entry)
        self.dateModified = date
    }
}

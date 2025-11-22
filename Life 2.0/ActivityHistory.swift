
import Foundation
import SwiftData

@Model
class ActivityHistory {
    @Relationship var activity: Activity?
    var dateCompleted: Date
    var dateRecorded: Date

    init(activity: Activity?, dateCompleted: Date = Date()) {
        self.activity = activity
        self.dateCompleted = dateCompleted
        self.dateRecorded = Date()
    }
}

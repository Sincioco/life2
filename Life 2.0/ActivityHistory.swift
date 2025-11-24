// ————————————————————————————————————————————————————————————————————————————————————————————————————
//                                      Life 2.0 - Activity History
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Programmed By:  Louiery R. Sincioco                                                     Version: 1.0
// Programmed Date:  November 23, 2025                                                      For: iOS 26
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Purpose:  A model to keep track of completed activities.
// ————————————————————————————————————————————————————————————————————————————————————————————————————

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

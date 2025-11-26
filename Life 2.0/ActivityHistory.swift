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


// MARK: - Backup Export / Import (ActivityHistory)
extension ActivityHistory {
    struct HistoryBackup: Codable {
        let activityName: String?
        let dateCompleted: Date
        let dateRecorded: Date
    }

    static func exportAll(in context: ModelContext) throws -> [HistoryBackup] {
        let descriptor = FetchDescriptor<ActivityHistory>()
        let all = try context.fetch(descriptor)
        return all.map { history in
            HistoryBackup(
                activityName: history.activity?.name,
                dateCompleted: history.dateCompleted,
                dateRecorded: history.dateRecorded
            )
        }
    }

    static func importAll(_ items: [HistoryBackup], in context: ModelContext) throws {
        let activities = try context.fetch(FetchDescriptor<Activity>())
        var lookup: [String: Activity] = [:]
        for activity in activities {
            lookup[activity.name] = activity
        }

        for item in items {
            let activity: Activity? = {
                if let name = item.activityName {
                    return lookup[name]
                } else {
                    return nil
                }
            }()

            let history = ActivityHistory(activity: activity, dateCompleted: item.dateCompleted)
            history.dateRecorded = item.dateRecorded
            context.insert(history)
        }
        //try context.save()
    }
}

//
//  Event.swift
//  Life 2.0
//
//  Created by Sin on 11/22/25.
//

import Foundation
import SwiftData

@Model
class Life2Event {
    var name: String
    var icon: String
    var recurrence: String
    var category: String
    var notes: String
    var dateCreated: Date
    var dateMreated: Date
    
    init(name: String, icon: String, recurrence: String, category: String, notes: String, dateCreated: Date, dateMreated: Date) {
        self.name = name
        self.icon = icon
        self.recurrence = recurrence
        self.category = category
        self.notes = notes
        self.dateCreated = dateCreated
        self.dateMreated = dateMreated
    }
}

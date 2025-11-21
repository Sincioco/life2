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
    var score: Double
    var icon: String
    var recurrence: String
    var category: String
    var notes: String
    var dateCreated: Date
    var dateModified: Date
    
    init(name: String, icon: String, score: Double, recurrence: String, category: String, notes: String, dateCreated: Date, dateModified: Date) {
        self.name = name
        self.icon = icon
        self.score = score
        self.recurrence = recurrence
        self.category = category
        self.notes = notes
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }
}

extension Life2Event {
    static var sampleData: [Life2Event] {
        [
            Life2Event(
                name: "Morning Run",
                icon: "figure.run",
                score: 10,
                recurrence: "Daily",
                category: "Fitness",
                notes: "5km easy pace",
                dateCreated: Date().addingTimeInterval(-86400 * 3),
                dateModified: Date()
            ),
            
            Life2Event(
                name: "Pay Electric Bill",
                icon: "bolt.fill",
                score: 3,
                recurrence: "Monthly",
                category: "Bills",
                notes: "Due every 25th",
                dateCreated: Date().addingTimeInterval(-86400 * 30),
                dateModified: Date()
            ),
            
            Life2Event(
                name: "Date Night",
                icon: "heart.fill",
                score: 8,
                recurrence: "Weekly",
                category: "Personal",
                notes: "Dinner with Joy 🍽️",
                dateCreated: Date().addingTimeInterval(-86400 * 10),
                dateModified: Date()
            ),
            
            Life2Event(
                name: "Leg Day",
                icon: "dumbbell.fill",
                score: 7,
                recurrence: "Weekly",
                category: "Fitness",
                notes: "Squats + Lunges + Leg Press",
                dateCreated: Date().addingTimeInterval(-86400 * 8),
                dateModified: Date()
            ),
            
            Life2Event(
                name: "Car Maintenance",
                icon: "car.fill",
                score: 2,
                recurrence: "Yearly",
                category: "Maintenance",
                notes: "Oil change + tune-up",
                dateCreated: Date().addingTimeInterval(-86400 * 200),
                dateModified: Date()
            )
        ]
    }
}

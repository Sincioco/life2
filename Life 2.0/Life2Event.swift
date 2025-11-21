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
            // FITNESS
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
                name: "Leg Day",
                icon: "dumbbell.fill",
                score: 7.5,
                recurrence: "Weekly",
                category: "Fitness",
                notes: "Squats, Lunges, Leg Press",
                dateCreated: Date().addingTimeInterval(-86400 * 8),
                dateModified: Date()
            ),
            Life2Event(
                name: "Yoga & Stretching",
                icon: "figure.cooldown",
                score: 5,
                recurrence: "Daily",
                category: "Fitness",
                notes: "15 minutes morning flexibility",
                dateCreated: Date().addingTimeInterval(-86400 * 5),
                dateModified: Date()
            ),
            
            // PERSONAL
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
                name: "Meditation",
                icon: "brain.head.profile",
                score: 4.5,
                recurrence: "Daily",
                category: "Personal",
                notes: "10 minutes mindfulness",
                dateCreated: Date().addingTimeInterval(-86400 * 1),
                dateModified: Date()
            ),
            Life2Event(
                name: "Call Parents",
                icon: "phone.fill",
                score: 3,
                recurrence: "Weekly",
                category: "Personal",
                notes: "Check in with family",
                dateCreated: Date().addingTimeInterval(-86400 * 12),
                dateModified: Date()
            ),
            
            // BILLS
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
                name: "Water Bill",
                icon: "drop.fill",
                score: 2,
                recurrence: "Monthly",
                category: "Bills",
                notes: "Auto-debit BPI",
                dateCreated: Date().addingTimeInterval(-86400 * 60),
                dateModified: Date()
            ),
            Life2Event(
                name: "Internet Bill",
                icon: "wifi",
                score: 2.5,
                recurrence: "Monthly",
                category: "Bills",
                notes: "Converge ₱1500",
                dateCreated: Date().addingTimeInterval(-86400 * 32),
                dateModified: Date()
            ),
            
            // WORK
            Life2Event(
                name: "Weekly Planning",
                icon: "calendar",
                score: 4,
                recurrence: "Weekly",
                category: "Work",
                notes: "Review tasks + sprint board",
                dateCreated: Date().addingTimeInterval(-86400 * 6),
                dateModified: Date()
            ),
            Life2Event(
                name: "1-on-1 Team Meeting",
                icon: "person.2.fill",
                score: 3.5,
                recurrence: "Weekly",
                category: "Work",
                notes: "Coaching + updates",
                dateCreated: Date().addingTimeInterval(-86400 * 14),
                dateModified: Date()
            ),
            Life2Event(
                name: "Project Refactor",
                icon: "hammer",
                score: 6,
                recurrence: "None",
                category: "Work",
                notes: "Clean up old Swift code",
                dateCreated: Date().addingTimeInterval(-86400 * 2),
                dateModified: Date()
            ),

            // MAINTENANCE
            Life2Event(
                name: "Car Maintenance",
                icon: "car.fill",
                score: 2,
                recurrence: "Yearly",
                category: "Maintenance",
                notes: "Oil change + tune-up",
                dateCreated: Date().addingTimeInterval(-86400 * 200),
                dateModified: Date()
            ),
            Life2Event(
                name: "Aircon Cleaning",
                icon: "wind",
                score: 3,
                recurrence: "Quarterly",
                category: "Maintenance",
                notes: "Split-type deep clean",
                dateCreated: Date().addingTimeInterval(-86400 * 90),
                dateModified: Date()
            ),
            Life2Event(
                name: "Grocery Restock",
                icon: "cart.fill",
                score: 2.5,
                recurrence: "Weekly",
                category: "Maintenance",
                notes: "Vegetables, fruit, chicken, oatmeal",
                dateCreated: Date().addingTimeInterval(-86400 * 4),
                dateModified: Date()
            ),
            
            // LEARNING
            Life2Event(
                name: "Learn SwiftUI",
                icon: "book.fill",
                score: 6.5,
                recurrence: "Daily",
                category: "Learning",
                notes: "1 hour coding practice",
                dateCreated: Date().addingTimeInterval(-86400 * 7),
                dateModified: Date()
            ),
            Life2Event(
                name: "Read Tech Articles",
                icon: "newspaper.fill",
                score: 3,
                recurrence: "Daily",
                category: "Learning",
                notes: "AI, Swift, and GPU news",
                dateCreated: Date().addingTimeInterval(-86400 * 2),
                dateModified: Date()
            ),
            Life2Event(
                name: "Watch WWDC Session",
                icon: "desktopcomputer",
                score: 4,
                recurrence: "Weekly",
                category: "Learning",
                notes: "Review SwiftData updates",
                dateCreated: Date().addingTimeInterval(-86400 * 11),
                dateModified: Date()
            )
        ]
    }
}

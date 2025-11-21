//
//  Event.swift
//  Life 2.0
//
//  Created by Sin on 11/22/25.
//

import Foundation
import SwiftData

@Model
class Activity {
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

extension Activity {
    
    private static func randomScore() -> Double {
        Double(Int.random(in: 1...100))
    }
    
    static var sampleData: [Activity] {
        [
            // FITNESS
            Activity(
                name: "Morning Run",
                icon: "figure.run",
                score: randomScore(),
                recurrence: "Daily",
                category: "Fitness",
                notes: "5km easy pace",
                dateCreated: Date().addingTimeInterval(-86400 * 3),
                dateModified: Date()
            ),
            Activity(
                name: "Leg Day",
                icon: "dumbbell.fill",
                score: randomScore(),
                recurrence: "Weekly",
                category: "Fitness",
                notes: "Squats, Lunges, Leg Press",
                dateCreated: Date().addingTimeInterval(-86400 * 8),
                dateModified: Date()
            ),
            Activity(
                name: "Yoga & Stretching",
                icon: "figure.cooldown",
                score: randomScore(),
                recurrence: "Daily",
                category: "Fitness",
                notes: "15 minutes morning flexibility",
                dateCreated: Date().addingTimeInterval(-86400 * 5),
                dateModified: Date()
            ),
            
            // PERSONAL
            Activity(
                name: "Date Night",
                icon: "heart.fill",
                score: randomScore(),
                recurrence: "Weekly",
                category: "Personal",
                notes: "Dinner with Joy 🍽️",
                dateCreated: Date().addingTimeInterval(-86400 * 10),
                dateModified: Date()
            ),
            Activity(
                name: "Meditation",
                icon: "brain.head.profile",
                score: randomScore(),
                recurrence: "Daily",
                category: "Personal",
                notes: "10 minutes mindfulness",
                dateCreated: Date().addingTimeInterval(-86400 * 1),
                dateModified: Date()
            ),
            Activity(
                name: "Call Parents",
                icon: "phone.fill",
                score: randomScore(),
                recurrence: "Weekly",
                category: "Personal",
                notes: "Check in with family",
                dateCreated: Date().addingTimeInterval(-86400 * 12),
                dateModified: Date()
            ),
            
            // BILLS
            Activity(
                name: "Pay Electric Bill",
                icon: "bolt.fill",
                score: randomScore(),
                recurrence: "Monthly",
                category: "Bills",
                notes: "Due every 25th",
                dateCreated: Date().addingTimeInterval(-86400 * 30),
                dateModified: Date()
            ),
            Activity(
                name: "Water Bill",
                icon: "drop.fill",
                score: randomScore(),
                recurrence: "Monthly",
                category: "Bills",
                notes: "Auto-debit BPI",
                dateCreated: Date().addingTimeInterval(-86400 * 60),
                dateModified: Date()
            ),
            Activity(
                name: "Internet Bill",
                icon: "wifi",
                score: randomScore(),
                recurrence: "Monthly",
                category: "Bills",
                notes: "Converge ₱1500",
                dateCreated: Date().addingTimeInterval(-86400 * 32),
                dateModified: Date()
            ),
            
            // WORK
            Activity(
                name: "Weekly Planning",
                icon: "calendar",
                score: randomScore(),
                recurrence: "Weekly",
                category: "Work",
                notes: "Review tasks + sprint board",
                dateCreated: Date().addingTimeInterval(-86400 * 6),
                dateModified: Date()
            ),
            Activity(
                name: "1-on-1 Team Meeting",
                icon: "person.2.fill",
                score: randomScore(),
                recurrence: "Weekly",
                category: "Work",
                notes: "Coaching + updates",
                dateCreated: Date().addingTimeInterval(-86400 * 14),
                dateModified: Date()
            ),
            Activity(
                name: "Project Refactor",
                icon: "hammer",
                score: randomScore(),
                recurrence: "None",
                category: "Work",
                notes: "Clean up old Swift code",
                dateCreated: Date().addingTimeInterval(-86400 * 2),
                dateModified: Date()
            ),

            // MAINTENANCE
            Activity(
                name: "Car Maintenance",
                icon: "car.fill",
                score: randomScore(),
                recurrence: "Yearly",
                category: "Maintenance",
                notes: "Oil change + tune-up",
                dateCreated: Date().addingTimeInterval(-86400 * 200),
                dateModified: Date()
            ),
            Activity(
                name: "Aircon Cleaning",
                icon: "wind",
                score: randomScore(),
                recurrence: "Quarterly",
                category: "Maintenance",
                notes: "Split-type deep clean",
                dateCreated: Date().addingTimeInterval(-86400 * 90),
                dateModified: Date()
            ),
            Activity(
                name: "Grocery Restock",
                icon: "cart.fill",
                score: randomScore(),
                recurrence: "Weekly",
                category: "Maintenance",
                notes: "Vegetables, fruit, chicken, oatmeal",
                dateCreated: Date().addingTimeInterval(-86400 * 4),
                dateModified: Date()
            ),
            
            // LEARNING
            Activity(
                name: "Learn SwiftUI",
                icon: "book.fill",
                score: randomScore(),
                recurrence: "Daily",
                category: "Learning",
                notes: "1 hour coding practice",
                dateCreated: Date().addingTimeInterval(-86400 * 7),
                dateModified: Date()
            ),
            Activity(
                name: "Read Tech Articles",
                icon: "newspaper.fill",
                score: randomScore(),
                recurrence: "Daily",
                category: "Learning",
                notes: "AI, Swift, and GPU news",
                dateCreated: Date().addingTimeInterval(-86400 * 2),
                dateModified: Date()
            ),
            Activity(
                name: "Watch WWDC Session",
                icon: "desktopcomputer",
                score: randomScore(),
                recurrence: "Weekly",
                category: "Learning",
                notes: "Review SwiftData updates",
                dateCreated: Date().addingTimeInterval(-86400 * 11),
                dateModified: Date()
            )
        ]
    }
}

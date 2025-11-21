//
//  Life_2_0App.swift
//  Life 2.0
//
//  Created by Sin on 11/19/25.
//

import SwiftUI
import SwiftData

@main
struct Life_2_0App: App {
    var body: some Scene {
        
        // Test Data Container (Part 1 of 2)
        let previewContainer: ModelContainer = {
            let schema = Schema([Activity.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: true)

            let container = try! ModelContainer(for: schema, configurations: config)

            // Insert test data
            for event in Activity.sampleData {
                container.mainContext.insert(event)
            }

            return container
        }()
        
        WindowGroup {
            //MainView()
            MainView()
            //SwiftUIGridView(year: 2025, month: 11)
        }
        
        //.modelContainer(for: Life2Event.self)
        
        // Test Data Container (Part 2 of 2)
        .modelContainer(previewContainer)    
        
    }
}

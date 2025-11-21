//
//  MainView2.swift
//  Life 2.0
//
//  Created by Sin on 11/22/25.
//

import Foundation
import SwiftUI
import SwiftData

struct MainView: View {
    
    var body: some View {
        
        TabView {
            Tab("Activities", systemImage: "list.bullet.rectangle") {
                ActivitiesView()
            }
            Tab("Calendar", systemImage: "calendar") {
                CalendarView(year: 2025, month: 11)
            }
//            Tab("Help", systemImage: "questionmark.circle") {
//            }
            Tab("Options", systemImage: "line.3.horizontal") {
            }
            Tab("Search", systemImage: "magnifyingglass", role: .search) {
     
                    ActivitiesView()
        
            }
        }
    }
    
}

#Preview {
    
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
    
    MainView()
        .modelContainer(previewContainer)
}

//
//  MainView2.swift
//  Life 2.0
//
//  Created by Sin on 11/22/25.
//

import Foundation
import SwiftUI
import SwiftData

struct MainView2: View {
    
    var body: some View {
        
        TabView {
            Tab("Activities", systemImage: "list.bullet.rectangle") {
                ListView()
            }
            Tab("Calendar", systemImage: "calendar") {
                CalendarView(year: 2025, month: 11)
            }
            Tab("Help", systemImage: "questionmark.circle") {
            }
            Tab("Options", systemImage: "line.3.horizontal") {
            }
        }
    }
    
}

#Preview {
    
    let previewContainer: ModelContainer = {
        let schema = Schema([Life2Event.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        
        let container = try! ModelContainer(for: schema, configurations: config)
        
        // Insert test data
        for event in Life2Event.sampleData {
            container.mainContext.insert(event)
        }
        
        return container
    }()
    
    MainView2()
        .modelContainer(previewContainer)
}

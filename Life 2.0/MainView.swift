// ————————————————————————————————————————————————————————————————————————————————————————————————————
//                                         Life 2.0 - Main View
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Programmed By:  Louiery R. Sincioco                                                     Version: 1.0
// Programmed Date:  November 19, 2025                                                      For: iOS 26
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Purpose:  Setup the main Tab view of the application.
// ————————————————————————————————————————————————————————————————————————————————————————————————————

import SwiftUI
import SwiftData

struct MainView: View {
    
    var body: some View {
        
        TabView {
            Tab("Activities", systemImage: "list.bullet.rectangle") {
                ActivitiesView()
            }
            Tab("Calendar", systemImage: "calendar") {
                CalendarView()
            }
            Tab("Overview", systemImage: "chart.bar.xaxis.ascending") {
                GraphView()
            }
            Tab("History", systemImage: "line.3.horizontal") {
                ActivityHistoryView()
            }
//            Tab("Pie", systemImage: "line.3.horizontal") {
//                SimplePieChartView()
//            }
            Tab("Options", systemImage: "gear") {
                OptionsView()
            }
        }
    }
    
}

#Preview {
    
    let previewContainer: ModelContainer = {
        let schema = Schema([Activity.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        
        let container = try! ModelContainer(for: schema, configurations: config)
        
        return container
    }()
    
    MainView()
        .modelContainer(previewContainer)
}

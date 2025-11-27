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
    @State var icon: String = ""
    
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
            Tab("Categories", systemImage: "folder") {
                CategoryListView()
            }
            Tab("Options", systemImage: "gear") {
                OptionsView()
            }
            Tab("Export / Import", systemImage: "arrow.up.arrow.down.circle") {
                ExportImportView()
            }
            Tab("Icon Viewer", systemImage: "xmark.triangle.circle.square") {
                IconPickerView(selectedIcon: $icon)
            }
            Tab("SF Symbol Exporter", systemImage: "xmark.triangle.circle.square") {
                SymbolExporter()
            }
            
            //
            
            //            Tab("Pie", systemImage: "line.3.horizontal") {
            //                SimplePieChartView()
            //            }
            //            Tab("Mesh Gradient", systemImage: "arrow.up.arrow.down.circle") {
            //                AnimatedGradientMeshBackground()
            //            }
            //            Tab("Mesh Gradient 2", systemImage: "arrow.up.arrow.down.circle") {
            //                //GradientMeshMotionBackground()
            //                GradientMeshBackground();
            //            }
            //            Tab("Mesh Gradient 3", systemImage: "arrow.up.arrow.down.circle") {
            //                GradientMeshMotionBackground()
            //            }
            //            Tab("Mesh Gradient 4", systemImage: "gear") {
            //                UnderwaterGradientMeshBackground()
            //            }
            //
            
            
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

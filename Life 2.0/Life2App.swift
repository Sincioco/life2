// ————————————————————————————————————————————————————————————————————————————————————————————————————
//                                      Life 2.0 - App Definition
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Programmed By:  Louiery R. Sincioco                                                     Version: 1.0
// Programmed Date:  November 19, 2025                                                      For: iOS 26
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Purpose:  Bootstraps the data containers and the initial view for the app.
// ————————————————————————————————————————————————————————————————————————————————————————————————————
import SwiftUI
import SwiftData

@main
struct Life2App: App {
    
    var body: some Scene {
        
        WindowGroup {
            MainView()
        }
        
        .modelContainer(for: Activity.self)
        
    }
}

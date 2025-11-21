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
        WindowGroup {
            MainView()
            //SwiftUIGridView(year: 2025, month: 11)
        }
        .modelContainer(for: Life2Event.self)
    }
}

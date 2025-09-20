//
//  GekoApp.swift
//  Geko
//
//  Created by Irenews on 9/19/25.
//

import SwiftUI
import SwiftData

@main
struct GekoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Habit.self)
    }
}

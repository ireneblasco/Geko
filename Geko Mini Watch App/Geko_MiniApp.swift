//
//  Geko_MiniApp.swift
//  Geko Mini Watch App
//
//  Created by Irenews on 9/20/25.
//

import SwiftUI
import SwiftData
import GekoShared

@main
struct Geko_Mini_Watch_AppApp: App {
    // Use the shared SwiftData container so the watch and widgets share data with the main app
    private let sharedContainer = SharedDataContainer.shared.modelContainer

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedContainer)
    }
}

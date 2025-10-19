//
//  GekoWatch.swift
//  GekoWatch
//
//  Created by Irenews on 9/20/25.
//

import SwiftUI
import SwiftData
import GekoShared
import WidgetKit

@main
struct GekoWatch: App {
    // Use the shared SwiftData container so the watch and widgets share data with the main app
    private let sharedContainer = SharedDataContainer.shared.modelContainer
    private let watchConnectivity = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Set up syncing with the model context
                    let modelContext = ModelContext(sharedContainer)
                    let syncManager = SyncManager.shared
                    syncManager.setModelContext(modelContext)
                    syncManager.updateSyncStatus()
                    print("⌚ Watch app initialized with sync status: \(syncManager.syncStatusDescription)")
                    
                    // Trigger a full sync on app open
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        syncManager.requestFullSync()
                        print("⌚ Watch app triggered full sync on launch")
                        WidgetCenter.shared.reloadAllTimelines()
                        print("⌚ Requested WidgetKit timeline reload from watch app")
                    }
                }
        }
        .modelContainer(sharedContainer)
    }
}

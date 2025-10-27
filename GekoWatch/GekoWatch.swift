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
import OSLog

@main
struct GekoWatch: App {
    // Use the shared SwiftData container so the watch and widgets share data with the main app
    private let sharedContainer = SharedDataContainer.shared.modelContainer
    private let watchConnectivity = WatchConnectivityManager.shared
    
    // Static logger for this file/app using shared subsystem
    private static let logger = Logger(subsystem: kGekoLogSubsystem, category: "GekoWatch")

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Set up syncing with the model context
                    let modelContext = ModelContext(sharedContainer)
                    let syncManager = SyncManager.shared
                    syncManager.setModelContext(modelContext)
                    syncManager.updateSyncStatus()
                    Self.logger.info("⌚ Watch app initialized with sync status: \(syncManager.syncStatusDescription, privacy: .public)")
                    
                    // Trigger a full sync on app open
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        syncManager.requestFullSync()
                        Self.logger.info("⌚ Watch app triggered full sync on launch")
                        WidgetCenter.shared.reloadAllTimelines()
                        Self.logger.info("⌚ Requested WidgetKit timeline reload from watch app")
                    }
                }
        }
        .modelContainer(sharedContainer)
    }
}

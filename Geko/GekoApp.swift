//
//  GekoApp.swift
//  Geko
//
//  Created by Irenews on 9/19/25.
//

import SwiftUI
import SwiftData
import GekoShared

@main
struct GekoApp: App {
    private let syncManager = SyncManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Initialize StoreManager to observe transactions and entitlements
                    _ = StoreManager.shared

                    // Set up syncing with the model context
                    let modelContext = ModelContext(SharedDataContainer.shared.modelContainer)
                    syncManager.setModelContext(modelContext)
                    syncManager.updateSyncStatus()
                    print("📱 iPhone app initialized with sync status: \(syncManager.syncStatusDescription)")
                    
                    // Trigger a full sync on app open
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        syncManager.requestFullSync()
                        print("📱 iPhone app triggered full sync on launch")
                    }
                }
        }
        .modelContainer(SharedDataContainer.shared.modelContainer)
    }
}

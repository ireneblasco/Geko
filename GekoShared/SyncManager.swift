//
//  SyncManager.swift
//  GekoShared
//
//  Created by Geko Assistant
//

import Foundation
import SwiftData
import CloudKit
import Combine

public enum SyncStatus {
    case hybridSync      // Both CloudKit and Watch Connectivity available
    case cloudKitOnly    // Only CloudKit available
    case watchOnly       // Only Watch Connectivity available
    case localOnly       // App Groups only
    case offline         // No sync available
}

public class SyncManager: ObservableObject {
    public static let shared = SyncManager()
    
    @Published public var syncStatus: SyncStatus = .offline
    @Published public var lastSyncDate: Date?
    @Published public var isSyncing = false
    
    private let watchConnectivity = WatchConnectivityManager.shared
    private var modelContext: ModelContext?
    
    private init() {
        updateSyncStatus()
        
        // Monitor Watch Connectivity status changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WatchConnectivityStatusChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateSyncStatus()
        }
    }
    
    public func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        watchConnectivity.setModelContext(context)
    }
    
    // MARK: - Sync Status Management
    
    public func updateSyncStatus() {
        DispatchQueue.main.async {
            // Check CloudKit availability
            CKContainer.default().accountStatus { [weak self] accountStatus, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    let isCloudKitAvailable = accountStatus == .available
                    let isWatchConnectivityAvailable = self.watchConnectivity.isReachable
                    
                    // Determine sync status based on available methods
                    switch (isCloudKitAvailable, isWatchConnectivityAvailable) {
                    case (true, true):
                        self.syncStatus = .hybridSync
                    case (true, false):
                        self.syncStatus = .cloudKitOnly
                    case (false, true):
                        self.syncStatus = .watchOnly
                    case (false, false):
                        self.syncStatus = .localOnly
                    }
                    
                    print("🔄 Sync status updated: \(self.syncStatusDescription)")
                }
            }
        }
    }
    
    // MARK: - Habit Syncing Methods
    
    public func syncHabitUpdate(_ habit: Habit) {
        switch syncStatus {
        case .hybridSync:
            // Best case: Use Watch Connectivity for immediate response, CloudKit for persistence
            watchConnectivity.syncHabitUpdate(habit)
            print("⚡ Hybrid sync: Immediate via Watch Connectivity + CloudKit persistence")
            
        case .cloudKitOnly:
            // CloudKit handles this automatically through SwiftData
            print("📱 Syncing habit update via CloudKit only")
            
        case .watchOnly:
            // Watch Connectivity only
            watchConnectivity.syncHabitUpdate(habit)
            print("⌚ Syncing habit update via Watch Connectivity only")
            
        case .localOnly, .offline:
            // Data is already saved locally via shared App Group
            print("💾 Habit saved locally via App Group")
        }
    }
    
    public func syncHabitCompletion(habitName: String, date: Date, isCompleted: Bool, completionCount: Int) {
        switch syncStatus {
        case .hybridSync:
            // Best case: Immediate Watch sync + CloudKit persistence
            watchConnectivity.syncHabitCompletion(
                habitName: habitName,
                date: date,
                isCompleted: isCompleted,
                completionCount: completionCount
            )
            print("⚡ Hybrid sync: Immediate completion via Watch Connectivity + CloudKit persistence")
            
        case .cloudKitOnly:
            // CloudKit handles this automatically through SwiftData
            print("📱 Syncing habit completion via CloudKit only")
            
        case .watchOnly:
            // Watch Connectivity only
            watchConnectivity.syncHabitCompletion(
                habitName: habitName,
                date: date,
                isCompleted: isCompleted,
                completionCount: completionCount
            )
            print("⌚ Syncing habit completion via Watch Connectivity only")
            
        case .localOnly, .offline:
            // Data is already saved locally via shared App Group
            print("💾 Habit completion saved locally via App Group")
        }
    }
    
    public func syncHabitDeletion(habitName: String, habitId: Int) {
        switch syncStatus {
        case .hybridSync:
            // Best case: Immediate Watch sync + CloudKit persistence
            watchConnectivity.syncHabitDeletion(habitName: habitName, habitId: habitId)
            print("⚡ Hybrid sync: Immediate deletion via Watch Connectivity + CloudKit persistence")
            
        case .cloudKitOnly:
            // CloudKit handles this automatically through SwiftData
            print("📱 Syncing habit deletion via CloudKit only")
            
        case .watchOnly:
            // Watch Connectivity only
            watchConnectivity.syncHabitDeletion(habitName: habitName, habitId: habitId)
            print("⌚ Syncing habit deletion via Watch Connectivity only")
            
        case .localOnly, .offline:
            // Data is already deleted locally via shared App Group
            print("💾 Habit deletion handled locally via App Group")
        }
    }
    
    public func requestFullSync() {
        isSyncing = true
        
        switch syncStatus {
        case .hybridSync:
            // Best case: Request immediate Watch sync, CloudKit syncs automatically
            watchConnectivity.requestFullSync()
            print("⚡ Hybrid sync: Requesting immediate full sync via Watch Connectivity + CloudKit automatic sync")
            
        case .cloudKitOnly:
            // CloudKit sync happens automatically
            print("📱 CloudKit sync is automatic")
            
        case .watchOnly:
            // Watch Connectivity only
            watchConnectivity.requestFullSync()
            print("⌚ Requesting full sync via Watch Connectivity only")
            
        case .localOnly, .offline:
            print("💾 Local sync - data is already shared via App Group")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isSyncing = false
            self.lastSyncDate = Date()
        }
    }
    
    // MARK: - Sync Status Information
    
    public var syncStatusDescription: String {
        switch syncStatus {
        case .hybridSync:
            return "⚡ Optimal sync: Instant Watch updates + iCloud persistence"
        case .cloudKitOnly:
            return "📱 Syncing across all devices via iCloud"
        case .watchOnly:
            return "⌚ Syncing with Apple Watch when both devices are active"
        case .localOnly:
            return "💾 Local syncing between iPhone and Apple Watch via App Groups"
        case .offline:
            return "❌ Offline - changes saved locally"
        }
    }
    
    public var syncCapabilities: [String] {
        switch syncStatus {
        case .hybridSync:
            return [
                "⚡ Best of both worlds: Instant responsiveness + reliable persistence",
                "🚀 Immediate Watch Connectivity sync for real-time updates",
                "☁️ iCloud sync ensures consistency across all devices",
                "🔄 Automatic conflict resolution with iCloud as source of truth"
            ]
        case .cloudKitOnly:
            return [
                "☁️ Cross-device sync via iCloud",
                "🔄 Automatic background sync",
                "💾 iPhone ↔ Apple Watch sync via App Groups",
                "⚠️ No real-time Watch sync (Watch not reachable)"
            ]
        case .watchOnly:
            return [
                "⌚ Real-time iPhone ↔ Apple Watch sync when both active",
                "💾 Local iPhone ↔ Apple Watch sync via App Groups",
                "⚠️ No cross-device sync (iCloud unavailable)"
            ]
        case .localOnly:
            return [
                "💾 iPhone ↔ Apple Watch sync via App Groups",
                "📱 All data stored locally",
                "⚠️ No cross-device sync (iCloud unavailable)",
                "⚠️ No real-time sync (Apple Watch not reachable)"
            ]
        case .offline:
            return [
                "❌ Limited functionality",
                "💾 Changes saved locally only"
            ]
        }
    }
    
    // MARK: - Manual Retry Methods
    
    public func retryCloudKitSync() {
        updateSyncStatus()
        if isCloudKitAvailable {
            requestFullSync()
        }
    }
    
    public func retryWatchConnectivity() {
        if WatchConnectivityManager.shared.isReachable {
            watchConnectivity.requestFullSync()
        }
    }
}

// MARK: - Convenience Extensions

public extension SyncManager {
    var isCloudKitAvailable: Bool {
        syncStatus == .hybridSync || syncStatus == .cloudKitOnly
    }
    
    var isWatchConnectivityAvailable: Bool {
        syncStatus == .hybridSync || syncStatus == .watchOnly
    }
    
    var hasOptimalSync: Bool {
        syncStatus == .hybridSync
    }
    
    var hasAnySyncCapability: Bool {
        syncStatus != .offline
    }
    
    var syncPriority: String {
        switch syncStatus {
        case .hybridSync:
            return "Watch first, iCloud persistence"
        case .cloudKitOnly:
            return "iCloud only"
        case .watchOnly:
            return "Watch Connectivity only"
        case .localOnly:
            return "Local App Groups only"
        case .offline:
            return "No sync available"
        }
    }
}

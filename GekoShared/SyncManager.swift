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
    case cloudKitAvailable
    case localOnly
    case watchConnectivityAvailable
    case offline
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
                    
                    switch accountStatus {
                    case .available:
                        self.syncStatus = .cloudKitAvailable
                    case .noAccount, .restricted, .couldNotDetermine:
                        if self.watchConnectivity.isReachable {
                            self.syncStatus = .watchConnectivityAvailable
                        } else {
                            self.syncStatus = .localOnly
                        }
                    @unknown default:
                        self.syncStatus = .localOnly
                    }
                }
            }
        }
    }
    
    // MARK: - Habit Syncing Methods
    
    public func syncHabitUpdate(_ habit: Habit) {
        switch syncStatus {
        case .cloudKitAvailable:
            // CloudKit handles this automatically through SwiftData
            print("📱 Syncing habit update via CloudKit")
            
        case .watchConnectivityAvailable:
            watchConnectivity.syncHabitUpdate(habit)
            print("⌚ Syncing habit update via Watch Connectivity")
            
        case .localOnly, .offline:
            // Data is already saved locally via shared App Group
            print("💾 Habit saved locally via App Group")
        }
    }
    
    public func syncHabitCompletion(habitName: String, date: Date, isCompleted: Bool, completionCount: Int) {
        switch syncStatus {
        case .cloudKitAvailable:
            // CloudKit handles this automatically through SwiftData
            print("📱 Syncing habit completion via CloudKit")
            
        case .watchConnectivityAvailable:
            watchConnectivity.syncHabitCompletion(
                habitName: habitName,
                date: date,
                isCompleted: isCompleted,
                completionCount: completionCount
            )
            print("⌚ Syncing habit completion via Watch Connectivity")
            
        case .localOnly, .offline:
            // Data is already saved locally via shared App Group
            print("💾 Habit completion saved locally via App Group")
        }
    }
    
    public func requestFullSync() {
        isSyncing = true
        
        switch syncStatus {
        case .cloudKitAvailable:
            // CloudKit sync happens automatically
            print("📱 CloudKit sync is automatic")
            
        case .watchConnectivityAvailable:
            watchConnectivity.requestFullSync()
            print("⌚ Requesting full sync via Watch Connectivity")
            
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
        case .cloudKitAvailable:
            return "✅ Syncing across all devices via iCloud"
        case .watchConnectivityAvailable:
            return "⌚ Syncing with Apple Watch when both devices are active"
        case .localOnly:
            return "📱 Local syncing between iPhone and Apple Watch via App Groups"
        case .offline:
            return "❌ Offline - changes saved locally"
        }
    }
    
    public var syncCapabilities: [String] {
        switch syncStatus {
        case .cloudKitAvailable:
            return [
                "✅ Cross-device sync via iCloud",
                "✅ Automatic background sync",
                "✅ iPhone ↔ Apple Watch sync via App Groups"
            ]
        case .watchConnectivityAvailable:
            return [
                "⌚ Real-time iPhone ↔ Apple Watch sync when both active",
                "📱 Local iPhone ↔ Apple Watch sync via App Groups",
                "⚠️ No cross-device sync (iCloud unavailable)"
            ]
        case .localOnly:
            return [
                "📱 iPhone ↔ Apple Watch sync via App Groups",
                "💾 All data stored locally",
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
        if syncStatus == .cloudKitAvailable {
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
        syncStatus == .cloudKitAvailable
    }
    
    var isWatchConnectivityAvailable: Bool {
        syncStatus == .watchConnectivityAvailable || syncStatus == .cloudKitAvailable
    }
    
    var hasAnySyncCapability: Bool {
        syncStatus != .offline
    }
}

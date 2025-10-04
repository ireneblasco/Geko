//
//  SyncStatusView.swift
//  GekoShared
//
//  Created by Geko Assistant
//

import SwiftUI

public struct SyncStatusView: View {
    @ObservedObject private var syncManager = SyncManager.shared
    @ObservedObject private var watchConnectivity = WatchConnectivityManager.shared
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            List {
                // Current Status Section
                Section("Current Sync Status") {
                    HStack {
                        statusIcon
                        VStack(alignment: .leading, spacing: 4) {
                            Text(syncStatusTitle)
                                .font(.headline)
                            Text(syncManager.syncStatusDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Capabilities Section
                Section("Available Features") {
                    ForEach(syncManager.syncCapabilities, id: \.self) { capability in
                        Label(capability, systemImage: iconForCapability(capability))
                            .font(.caption)
                    }
                }
                
                // Connection Details
                Section("Connection Details") {
                    HStack {
                        Label("Apple Watch", systemImage: "applewatch")
                        Spacer()
                        Text(watchConnectivity.isReachable ? "Connected" : "Not Connected")
                            .foregroundColor(watchConnectivity.isReachable ? .green : .secondary)
                    }
                    
                    HStack {
                        Label("iCloud Account", systemImage: "icloud")
                        Spacer()
                        Text(syncManager.isCloudKitAvailable ? "Available" : "Unavailable")
                            .foregroundColor(syncManager.isCloudKitAvailable ? .green : .orange)
                    }
                    
                    if let lastSync = syncManager.lastSyncDate {
                        HStack {
                            Label("Last Sync", systemImage: "clock")
                            Spacer()
                            Text(lastSync, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Actions Section
                Section("Actions") {
                    if !syncManager.isCloudKitAvailable {
                        Button(action: {
                            syncManager.retryCloudKitSync()
                        }) {
                            Label("Retry iCloud Connection", systemImage: "icloud.and.arrow.up")
                        }
                    }
                    
                    if syncManager.hasAnySyncCapability {
                        Button(action: {
                            syncManager.requestFullSync()
                        }) {
                            HStack {
                                Label("Sync Now", systemImage: "arrow.clockwise")
                                if syncManager.isSyncing {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                        }
                        .disabled(syncManager.isSyncing)
                    }
                }
                
                // Help Section
                Section("Need Help?") {
                    VStack(alignment: .leading, spacing: 12) {
                        helpText
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Sync Status")
            .refreshable {
                syncManager.updateSyncStatus()
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var statusIcon: some View {
        Image(systemName: syncStatusIconName)
            .foregroundColor(syncStatusColor)
            .font(.title2)
    }
    
    private var syncStatusTitle: String {
        switch syncManager.syncStatus {
        case .cloudKitAvailable:
            return "iCloud Sync Active"
        case .watchConnectivityAvailable:
            return "Watch Connectivity Active"
        case .localOnly:
            return "Local Sync Only"
        case .offline:
            return "Offline Mode"
        }
    }
    
    private var syncStatusIconName: String {
        switch syncManager.syncStatus {
        case .cloudKitAvailable:
            return "icloud.and.arrow.up.fill"
        case .watchConnectivityAvailable:
            return "applewatch.and.arrow.forward"
        case .localOnly:
            return "internaldrive"
        case .offline:
            return "wifi.slash"
        }
    }
    
    private var syncStatusColor: Color {
        switch syncManager.syncStatus {
        case .cloudKitAvailable:
            return .green
        case .watchConnectivityAvailable:
            return .blue
        case .localOnly:
            return .yellow
        case .offline:
            return .red
        }
    }
    
    private func iconForCapability(_ capability: String) -> String {
        if capability.contains("✅") {
            return "checkmark.circle.fill"
        } else if capability.contains("⌚") {
            return "applewatch"
        } else if capability.contains("📱") {
            return "iphone"
        } else if capability.contains("⚠️") {
            return "exclamationmark.triangle"
        } else if capability.contains("❌") {
            return "xmark.circle"
        } else {
            return "info.circle"
        }
    }
    
    private var helpText: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Understanding Sync Methods:")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• **iCloud Sync**: Best option - syncs across all your devices automatically")
                Text("• **Watch Connectivity**: Real-time sync when iPhone and Watch are both active")
                Text("• **App Groups**: Local sync between iPhone and Watch (always works)")
                Text("• **Local Only**: Data is saved but won't sync to other devices")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Text("To enable iCloud sync, sign into iCloud in Settings and ensure iCloud is enabled for this app.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }
}

#Preview {
    SyncStatusView()
}

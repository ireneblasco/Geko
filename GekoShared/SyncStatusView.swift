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
        case .hybridSync:
            return "Optimal Hybrid Sync"
        case .cloudKitOnly:
            return "iCloud Sync Active"
        case .watchOnly:
            return "Watch Connectivity Active"
        case .localOnly:
            return "Local Sync Only"
        case .offline:
            return "Offline Mode"
        }
    }
    
    private var syncStatusIconName: String {
        switch syncManager.syncStatus {
        case .hybridSync:
            return "bolt.circle.fill"
        case .cloudKitOnly:
            return "icloud.and.arrow.up.fill"
        case .watchOnly:
            return "applewatch.and.arrow.forward"
        case .localOnly:
            return "internaldrive"
        case .offline:
            return "wifi.slash"
        }
    }
    
    private var syncStatusColor: Color {
        switch syncManager.syncStatus {
        case .hybridSync:
            return .purple
        case .cloudKitOnly:
            return .green
        case .watchOnly:
            return .blue
        case .localOnly:
            return .yellow
        case .offline:
            return .red
        }
    }
    
    private func iconForCapability(_ capability: String) -> String {
        if capability.contains("⚡") {
            return "bolt.circle.fill"
        } else if capability.contains("🚀") {
            return "rocket.fill"
        } else if capability.contains("☁️") {
            return "icloud.fill"
        } else if capability.contains("🔄") {
            return "arrow.clockwise.circle.fill"
        } else if capability.contains("✅") {
            return "checkmark.circle.fill"
        } else if capability.contains("⌚") {
            return "applewatch"
        } else if capability.contains("📱") || capability.contains("💾") {
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
                Text("• **Hybrid Sync**: Optimal - instant Watch updates + iCloud persistence")
                Text("• **iCloud Only**: Cross-device sync via iCloud (Watch not reachable)")
                Text("• **Watch Only**: Real-time sync when both devices are active")
                Text("• **App Groups**: Local sync between iPhone and Watch (always works)")
                Text("• **Local Only**: Data is saved but won't sync to other devices")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Text("**Hybrid Sync Strategy**: When both iCloud and Watch are available, changes sync immediately to your Watch for responsiveness, while iCloud ensures consistency across all devices and serves as the source of truth.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
            
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

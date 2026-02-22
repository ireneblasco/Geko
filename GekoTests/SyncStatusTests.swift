//
//  SyncStatusTests.swift
//  GekoTests
//
//  ViewInspector tests for iCloud syncing feature (#12)
//

import SwiftUI
import Testing
import ViewInspector
import GekoShared

struct SyncStatusTests {

    @Test @MainActor func syncStatusView_rendersListWithSections() throws {
        let view = SyncStatusView()
        _ = try view.inspect().find(ViewType.List.self)
    }

    @Test @MainActor func syncStatusView_showsCurrentStatusSection() throws {
        let view = SyncStatusView()
        _ = try view.inspect().find(text: "Current Sync Status")
    }

    @Test @MainActor func syncStatusView_showsConnectionDetails() throws {
        let view = SyncStatusView()
        _ = try view.inspect().find(text: "Apple Watch")
        _ = try view.inspect().find(text: "iCloud Account")
    }

    @Test @MainActor func syncStatusView_displaysStatusTitle() throws {
        let view = SyncStatusView()
        let statusTitles: Set<String> = [
            "Optimal Hybrid Sync",
            "iCloud Sync Active",
            "Watch Connectivity Active",
            "Local Sync Only",
            "Offline Mode"
        ]
        let texts = try view.inspect().findAll(ViewType.Text.self)
        let hasStatusTitle = texts.contains { statusTitles.contains((try? $0.string()) ?? "") }
        #expect(hasStatusTitle)
    }

    @Test @MainActor func syncStatusView_showsAvailableFeaturesSection() throws {
        let view = SyncStatusView()
        _ = try view.inspect().find(text: "Available Features")
    }
}

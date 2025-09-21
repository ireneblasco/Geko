//
//  GekoShared.swift
//  GekoShared
//
//  Created by Irenews on 9/20/25.
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - GekoShared Module
// This module exports reusable business logic and UI components for habit tracking.
// All types are already made public in their respective files.

// MARK: - Shared Data Container
public class SharedDataContainer {
    public static let shared = SharedDataContainer()
    
    // App Group identifier for sharing data between app and widget
    public static let appGroupIdentifier = "group.com.irenews.geko"
    
    private init() {}
    
    public lazy var modelContainer: ModelContainer = {
        let schema = Schema([Habit.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: sharedStoreURL,
            cloudKitDatabase: .automatic
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    private var sharedStoreURL: URL {
        let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier)
        guard let url = appGroupURL else {
            fatalError("Could not get shared container URL for App Group: \(Self.appGroupIdentifier)")
        }
        return url.appendingPathComponent("Geko.sqlite")
    }
}


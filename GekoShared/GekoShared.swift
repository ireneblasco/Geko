//
//  GekoShared.swift
//  GekoShared
//
//  Created by Irenews on 9/20/25.
//

import Foundation
import SwiftUI
import SwiftData
import CloudKit

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
        
        // Try CloudKit configuration first, fallback to local-only if it fails
        let modelConfiguration: ModelConfiguration
        
        do {
            // First attempt: CloudKit enabled
            modelConfiguration = ModelConfiguration(
                schema: schema,
                url: sharedStoreURL,
                cloudKitDatabase: .automatic
            )
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ Successfully initialized ModelContainer with CloudKit")
            return container
        } catch {
            print("⚠️ CloudKit initialization failed: \(error)")
            print("📱 Falling back to local-only storage")
            
            // Fallback: Local-only configuration
            do {
                let localConfiguration = ModelConfiguration(
                    schema: schema,
                    url: sharedStoreURL,
                    cloudKitDatabase: .none
                )
                let container = try ModelContainer(for: schema, configurations: [localConfiguration])
                print("✅ Successfully initialized ModelContainer in local-only mode")
                return container
            } catch {
                fatalError("Could not create ModelContainer even in local-only mode: \(error)")
            }
        }
    }()
    
    private var sharedStoreURL: URL {
        let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier)
        if let url = appGroupURL {
            print("✅ App Group container found at: \(url.path)")
            return url.appendingPathComponent("Geko.sqlite")
        } else {
            print("⚠️ Could not access App Group: \(Self.appGroupIdentifier)")
            print("⚠️ Falling back to default container")
            // Fallback to app's documents directory
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            return documentsURL.appendingPathComponent("Geko.sqlite")
        }
    }
}


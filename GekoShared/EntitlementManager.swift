//
//  EntitlementManager.swift
//  GekoShared
//
//  Manages isPlus entitlement state and syncs to App Group for widgets.
//

import Foundation
import Combine

/// Shared storage key for App Group UserDefaults.
public let isPlusUserDefaultsKey = "isPlus"

/// Observes and persists Geko Plus entitlement. Widgets read from App Group.
public final class EntitlementManager: ObservableObject {
    public static let shared = EntitlementManager()

    private let defaults: UserDefaults?
    private let defaultsKey = isPlusUserDefaultsKey

    @Published public private(set) var isPlus: Bool {
        didSet {
            defaults?.set(isPlus, forKey: defaultsKey)
        }
    }

    private init() {
        defaults = UserDefaults(suiteName: SharedDataContainer.appGroupIdentifier)
        isPlus = defaults?.bool(forKey: defaultsKey) ?? false
    }

    /// Called by StoreManager after successful purchase or restore.
    public func setPlus(_ value: Bool) {
        guard isPlus != value else { return }
        isPlus = value
    }
}

//
//  URLSchemeHandler.swift
//  Geko
//
//  Handles geko:// URLs for external app integration (complete, toggle, x-callback-url).
//

import SwiftUI
import SwiftData
import WidgetKit
import GekoShared

enum URLSchemeHandler {
    /// Handles geko:// URLs. Returns true if the URL was handled.
    @MainActor
    static func handle(_ url: URL) -> Bool {
        guard url.scheme == "geko" else { return false }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var queryItems: [String: String] = [:]
        for item in components?.queryItems ?? [] {
            if let value = item.value {
                queryItems[item.name] = value
            }
        }

        let habitName = queryItems["habit"]?.removingPercentEncoding ?? ""
        let xSuccess = queryItems["x-success"].flatMap { URL(string: $0) }
        let xError = queryItems["x-error"].flatMap { URL(string: $0) }
        let isXCallback = url.host == "x-callback-url"

        func openCallback(_ urlToOpen: URL?) {
            guard let urlToOpen else { return }
            UIApplication.shared.open(urlToOpen)
        }

        // Determine action from host or path (for x-callback-url)
        let action: String
        if isXCallback {
            let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            action = path.isEmpty ? "complete" : path
        } else {
            action = url.host ?? "complete"
        }

        switch action.lowercased() {
        case "paywall":
            return false // Let ContentView handle paywall
        case "complete":
            let success = performComplete(habitName: habitName)
            if isXCallback {
                openCallback(success ? xSuccess : xError)
            }
            return true
        case "toggle":
            let success = performToggle(habitName: habitName)
            if isXCallback {
                openCallback(success ? xSuccess : xError)
            }
            return true
        default:
            return false
        }
    }

    @MainActor
    private static func performComplete(habitName: String) -> Bool {
        guard !habitName.isEmpty else { return false }
        let container = SharedDataContainer.shared.modelContainer
        let context = container.mainContext

        let predicate = #Predicate<Habit> { h in h.name == habitName }
        let descriptor = FetchDescriptor<Habit>(predicate: predicate)

        guard let habits = try? context.fetch(descriptor),
              let habit = habits.first else {
            return false
        }

        habit.incrementCompletion()
        try? context.save()

        SyncManager.shared.syncHabitCompletion(
            habitName: habit.name,
            date: Date(),
            isCompleted: habit.isCompleted(),
            completionCount: habit.completionCount()
        )
        WidgetCenter.shared.reloadAllTimelines()
        return true
    }

    @MainActor
    private static func performToggle(habitName: String) -> Bool {
        guard !habitName.isEmpty else { return false }
        let container = SharedDataContainer.shared.modelContainer
        let context = container.mainContext

        let predicate = #Predicate<Habit> { h in h.name == habitName }
        let descriptor = FetchDescriptor<Habit>(predicate: predicate)

        guard let habits = try? context.fetch(descriptor),
              let habit = habits.first else {
            return false
        }

        if habit.isCompleted() {
            habit.resetCompletion()
        } else {
            if habit.dailyTarget > 1 {
                habit.incrementCompletion()
            } else {
                habit.toggleCompleted()
            }
        }

        try? context.save()

        SyncManager.shared.syncHabitCompletion(
            habitName: habit.name,
            date: Date(),
            isCompleted: habit.isCompleted(),
            completionCount: habit.completionCount()
        )
        WidgetCenter.shared.reloadAllTimelines()
        return true
    }
}

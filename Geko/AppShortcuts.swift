//
//  AppShortcuts.swift
//  Geko
//
//  Exposes Geko intents to the Shortcuts app, Siri, and Spotlight.
//

import AppIntents
import GekoShared

struct GekoShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CompleteHabitIntent(),
            phrases: [
                "Complete \(.applicationName) habit",
                "Log habit in \(.applicationName)",
                "Mark habit done in \(.applicationName)"
            ],
            shortTitle: "Complete Habit",
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: ToggleHabitIntent(),
            phrases: [
                "Toggle \(.applicationName) habit",
                "Toggle habit in \(.applicationName)"
            ],
            shortTitle: "Toggle Habit",
            systemImageName: "arrow.uturn.backward.circle"
        )
    }
}

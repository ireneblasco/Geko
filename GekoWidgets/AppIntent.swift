//
//  AppIntent.swift
//  GekoWidgets
//
//  Created by Irenews on 9/20/25.
//
//  Widget configuration intent. HabitEntity, HabitQuery, CompleteHabitIntent,
//  and ToggleHabitIntent are defined in GekoShared/AppIntents.swift.
//

import WidgetKit
import AppIntents
import GekoShared

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Select Habit" }
    static var description: IntentDescription { "Choose which habit to display in the widget." }

    @Parameter(title: "Habit", description: "The habit to track in this widget")
    var selectedHabit: HabitEntity?

    // Legacy property for backwards compatibility
    var habitName: String {
        return selectedHabit?.name ?? "Water"
    }
}

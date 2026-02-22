//
//  GekoWidgets.swift
//  GekoWidgets
//
//  Created by Irenews on 9/20/25.
//

import WidgetKit
import SwiftUI
import GekoShared

extension View {
    func widgetBackground(backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}

struct GekoWidgetsEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            if entry.isLocked {
                LockedWidgetView()
            } else if let habit = entry.habit {
                HabitWidgetView(habit: habit, family: family)
            } else {
                PlaceholderView(habitName: entry.configuration.habitName)
            }
        }
        .widgetBackground(backgroundView: Color(.systemBackground))
        .widgetURL(entry.isLocked ? URL(string: "geko://paywall") : nil)
        .accessibilityIdentifier("geko_habit_widget")
    }
}


struct GekoWidgets: Widget {
    let kind: String = "GekoWidgets"
    
    static let supportedFamilies: [WidgetFamily] = {
        #if os(watchOS)
        [.accessoryCircular, .accessoryRectangular, .accessoryCorner]
        #else
        [.systemSmall, .systemMedium]
        #endif
    }()

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            GekoWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("Habit Tracker")
        .description("Track your daily habits with a year view.")
        .supportedFamilies(Self.supportedFamilies)
    }
}

extension ConfigurationAppIntent {
    fileprivate static var sample: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.selectedHabit = HabitEntity(id: "Water", name: "Drink Water", emoji: "💧")
        return intent
    }
}

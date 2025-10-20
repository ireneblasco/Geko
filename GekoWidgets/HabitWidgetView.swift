//
//  HabitWidgetView.swift
//  GekoWidgets
//
//  Created by Irenews on 9/21/25.
//

import WidgetKit
import SwiftUI
import GekoShared

struct HabitWidgetView: View {
    let habit: Habit
    let family: WidgetFamily
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallHabitWidgetView(habit: habit)
        case .systemMedium:
            MediumHabitWidgetView(habit: habit)
        case .accessoryCircular:
            AccessoryCircularHabitView(habit: habit)
        case .accessoryRectangular:
            AccessoryRectangularHabitView(habit: habit)
        case .accessoryCorner:
            AccessoryCircularHabitView(habit: habit)
        default:
            Text(habit.emoji)
        }
    }
}


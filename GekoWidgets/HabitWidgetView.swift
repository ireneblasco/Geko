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
        if family == .systemSmall {
            SmallHabitWidgetView(habit: habit)
        } else {
            MediumHabitWidgetView(habit: habit)
        }
    }
}

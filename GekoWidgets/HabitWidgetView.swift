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
            Gauge(value: 1) {
                Text(habit.name)
            } currentValueLabel: {
                Text(habit.emoji)
            }
            .gaugeStyle(.accessoryCircular)
        case .accessoryRectangular:
            HStack(alignment: .center, spacing: 6) {
                Text(habit.emoji)
                    .font(.system(size: 18))
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.system(.caption2))
                        .lineLimit(1)
                    // Simplified progress text for rectangular accessory
                    Text("Today")
                        .font(.system(.caption2))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .accessoryCorner:
            ZStack {
                // Corner widgets are small; keep it concise
                Text(habit.emoji)
                    .font(.system(size: 14))
            }
        default:
            Text(habit.emoji)
        }
    }
}

//
//  SmallHabitWidgetView.swift
//  GekoWidgets
//
//  Created by Irenews on 9/21/25.
//

import WidgetKit
import SwiftUI
import GekoShared

struct SmallHabitWidgetView: View {
    let habit: Habit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Small widget layout - emoji with completion circle is the button
            HStack(spacing: 0) {
                Button(intent: ToggleHabitIntent(habitName: habit.name)) {
                    HabitRing(
                        progress: habit.completionProgress(),
                        color: habit.color.color,
                        emoji: habit.emoji,
                        size: 32,
                        lineWidth: 2.5
                    )
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(habit.name)
                        .font(.headline)
                        .lineLimit(1)
                    Text(completionText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }.padding(.leading, 8)
                
                Spacer()
            }.padding(.bottom, 12)
            
            // Year grid for small widget
            YearHabitGrid(
                habit: habit,
                weekCount: 12, // 12 weeks for small widget
                dotSize: 4,
                columnSpacing: 1,
                rowSpacing: 1
            )
        }
    }
    
    private var completionText: String {
        let count = habit.completionCount()
        let target = habit.dailyTarget
        
        if habit.isCompleted() {
            return "Complete (\(count)/\(target))"
        } else if count > 0 {
            return "Progress (\(count)/\(target))"
        } else {
            return "Not done today"
        }
    }
}


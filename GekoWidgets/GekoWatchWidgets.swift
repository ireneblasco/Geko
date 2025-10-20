//
//  GekoWatchWidgets.swift
//  GekoWidgets
//
//  Created by Geko Assistant on 10/19/25.
//

import SwiftUI
import WidgetKit
import GekoShared

// MARK: - watchOS Accessory Views

struct AccessoryCircularHabitView: View {
    let habit: Habit
    
    var body: some View {
        // Wrap HabitRing with an AppIntent button for interaction
        Button(intent: ToggleHabitIntent(habitName: habit.name)) {
            HabitRing(
                progress: habit.completionProgress(),
                color: habit.color.color,
                emoji: habit.emoji,
                size: 28,         // tuned for accessoryCircular
                lineWidth: 2.0,
                animated: false   // no animation in widget/complication
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .containerBackground(for: .widget) {
            Color.clear
        }
        .accessibilityLabel("\(habit.name)")
        .accessibilityValue("\(habit.completionCount()) of \(habit.dailyTarget) today")
    }
}

struct AccessoryRectangularHabitView: View {
    let habit: Habit
    
    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            // Make the ring tappable via AppIntent
            Button(intent: ToggleHabitIntent(habitName: habit.name)) {
                HabitRing(
                    progress: habit.completionProgress(),
                    color: habit.color.color,
                    emoji: habit.emoji,
                    lineWidth: 2.0,
                    animated: false
                )
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.system(.caption2))
                    .lineLimit(1)
                
                // Mini 7-day strip like the watch app row
                WeekTrackStrip(habit: habit)
                    .padding(.top, 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Mini Week Track Strip (widget-safe)

private struct WeekTrackStrip: View {
    enum DayStatus {
        case none, partial, full
    }
    
    @Environment(\.calendar) private var calendar
    let habit: Habit
    
    private func sevenDaysEndingToday(for reference: Date, calendar: Calendar) -> [Date] {
        var cal = calendar
        cal.locale = calendar.locale
        let end = cal.startOfDay(for: reference)
        guard let start = cal.date(byAdding: .day, value: -6, to: end) else {
            return [end]
        }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }
    
    private var weekDays: [Date] {
        sevenDaysEndingToday(for: Date(), calendar: calendar)
    }
    
    private func status(for date: Date) -> DayStatus {
        if habit.isCompleted(on: date, calendar: calendar) {
            return .full
        } else if habit.isPartiallyCompleted(on: date, calendar: calendar) {
            return .partial
        } else {
            return .none
        }
    }
    
    var body: some View {
        let color = habit.color.color
        HStack(spacing: 3) {
            ForEach(weekDays, id: \.self) { day in
                let st = status(for: day)
                ZStack {
                    Circle()
                        .stroke(color.opacity(0.25), lineWidth: 1)
                        .background(
                            Circle()
                                .fill(color.opacity(habit.completionProgress(on: day, calendar: calendar)))
                        )
                }
                .frame(width: 5.5, height: 5.5) // tighter for accessory rectangular
                .accessibilityLabel(accessibilityLabel(for: day, status: st))
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    private func accessibilityLabel(for date: Date, status: DayStatus) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        let dateString = formatter.string(from: date)
        let statusString: String
        switch status {
        case .none:
            statusString = "Not done"
        case .partial:
            let count = habit.completionCount(on: date, calendar: calendar)
            statusString = "Progress \(count)/\(habit.dailyTarget)"
        case .full:
            let count = habit.completionCount(on: date, calendar: calendar)
            statusString = "Complete \(count)/\(habit.dailyTarget)"
        }
        return "\(dateString): \(statusString)"
    }
}

// MARK: - Previews (watchOS only)

#if os(watchOS)
private struct WidgetPreviewWrapper<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        content()
            .containerBackground(for: .widget) {
                Color.clear
            }
    }
}

struct GekoWatchWidgets_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WidgetPreviewWrapper {
                AccessoryCircularHabitView(habit: sampleHabit)
            }
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Accessory Circular")
            
            WidgetPreviewWrapper {
                AccessoryRectangularHabitView(habit: sampleHabit)
            }
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("Accessory Rectangular")
            
            WidgetPreviewWrapper {
                AccessoryCircularHabitView(habit: sampleHabit)
            }
            .previewContext(WidgetPreviewContext(family: .accessoryCorner))
            .previewDisplayName("Accessory Corner")
        }
    }
    
    private static var sampleHabit: Habit {
        let h = Habit(name: "Drink Water", emoji: "💧", color: .blue, dailyTarget: 8)
        // Simulate some progress
        for _ in 0..<3 { h.incrementCompletion() }
        return h
    }
}
#endif

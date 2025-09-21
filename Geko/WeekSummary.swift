import SwiftUI
import SwiftData
import GekoShared

struct WeekSummary: View {
    @Environment(\.modelContext) private var context
    @Bindable var habit: Habit

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    private var weekDays: [Date] {
        WeekSummary.weekDates(for: Date(), calendar: calendar)
    }
    
    private var weekCompletedCount: Int {
        weekDays.reduce(0) { partial, day in
            partial + (habit.isCompleted(on: day, calendar: calendar) ? 1 : 0)
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(weekDays, id: \.self) { day in
                let isToday = calendar.isDateInToday(day)
                let wasDone = habit.isCompleted(on: day, calendar: calendar)
                let label = WeekSummary.shortWeekdaySymbol(for: day, calendar: calendar, locale: locale)

                Button {
                    let wasDone = habit.isCompleted(on: day, calendar: calendar)
                    
                    if wasDone {
                        // If already completed, reset the day
                        habit.resetCompletion(on: day, calendar: calendar)
                    } else {
                        // Use increment instead of toggle for multi-target habits
                        if habit.dailyTarget > 1 {
                            habit.incrementCompletion(on: day, calendar: calendar)
                        } else {
                            habit.toggleCompleted(on: day, calendar: calendar)
                        }
                        
                        // Play sound if we just completed the habit (reached target)
                        if habit.isCompleted(on: day, calendar: calendar) {
                            SoundFeedback.playCheck()
                        }
                    }
                    
                    try? context.save()
                } label: {
                    VStack(spacing: 4) {
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        let completionProgress = habit.completionProgress(on: day, calendar: calendar)
                        let completionCount = habit.completionCount(on: day, calendar: calendar)
                        let isFullyCompleted = habit.isCompleted(on: day, calendar: calendar)
                        
                        ZStack {
                            // Base circle with opacity-based completion indication
                            Circle()
                                .fill(completionProgress > 0 ? 
                                      habit.color.color.opacity(0.3 + (completionProgress * 0.7)) : 
                                      Color.secondary.opacity(0.15))
                                .frame(width: 26, height: 26)
                            
                            // Show checkmark only when fully completed
                            if isFullyCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .overlay {
                            if isToday {
                                Circle()
                                    .strokeBorder(habit.color.color.opacity(0.9), lineWidth: 2)
                                    .frame(width: 26, height: 26)
                            }
                        }
                    }
                    .frame(minWidth: 34)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel(for: day, label: label))
            }

            Spacer(minLength: 8)
        }
        .padding(.top, 2)
    }

    private func accessibilityLabel(for day: Date, label: String) -> String {
        let completionCount = habit.completionCount(on: day, calendar: calendar)
        let target = habit.dailyTarget
        
        if completionCount == 0 {
            return "\(label): Not done"
        } else if completionCount >= target {
            return "\(label): Complete (\(completionCount)/\(target))"
        } else {
            return "\(label): Partial (\(completionCount)/\(target))"
        }
    }

    // Helpers to compute the current week aligned to the user's firstWeekday
    static func weekDates(for reference: Date, calendar: Calendar) -> [Date] {
        var cal = calendar
        cal.locale = calendar.locale
        let startOfDay = cal.startOfDay(for: reference)
        let weekday = cal.component(.weekday, from: startOfDay)
        let firstWeekday = cal.firstWeekday
        let deltaToStart = (weekday - firstWeekday + 7) % 7
        guard let startOfWeek = cal.date(byAdding: .day, value: -deltaToStart, to: startOfDay) else {
            return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: startOfDay) }
        }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    static func shortWeekdaySymbol(for date: Date, calendar: Calendar, locale: Locale) -> String {
        var cal = calendar
        cal.locale = locale
        let formatter = DateFormatter()
        formatter.calendar = cal
        formatter.locale = locale
        let symbols = formatter.shortWeekdaySymbols ?? formatter.weekdaySymbols ?? ["S","M","T","W","T","F","S"]
        let idx = cal.component(.weekday, from: date) - 1
        if idx >= 0, idx < symbols.count {
            let sym = symbols[idx]
            if sym.count == 1 { return sym }
            return String(sym.prefix(1)).uppercased()
        }
        return "?"
    }
}

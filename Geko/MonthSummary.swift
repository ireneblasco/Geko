import SwiftUI
import SwiftData
import GekoShared

struct MonthSummary: View {
    @Environment(\.modelContext) private var context
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    @Bindable var habit: Habit
    let referenceDate: Date

    // Dot sizing: smaller than WeekSummary (26pt). Use 18pt with a smaller checkmark and outline.
    private let dotSize: CGFloat = 18
    private let checkmarkSize: CGFloat = 9
    private let todayOutlineWidth: CGFloat = 1.5
    private let columnSpacing: CGFloat = 6
    private let rowSpacing: CGFloat = 6

    init(habit: Habit, referenceDate: Date = Date()) {
        self.habit = habit
        self.referenceDate = referenceDate
    }

    private var monthGrid: [[Date?]] {
        MonthSummary.monthGrid(for: referenceDate, calendar: calendar)
    }

    private var weekdayHeader: [String] {
        // Use the same single-letter symbol logic as WeekSummary
        let anyWeek = WeekSummary.weekDates(for: referenceDate, calendar: calendar)
        return anyWeek.map { WeekSummary.shortWeekdaySymbol(for: $0, calendar: calendar, locale: locale) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Weekday headers aligned to firstWeekday
            HStack(spacing: columnSpacing) {
                ForEach(Array(weekdayHeader.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            VStack(spacing: rowSpacing) {
                ForEach(Array(monthGrid.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: columnSpacing) {
                        ForEach(0..<7, id: \.self) { col in
                            let day = week[col]
                            Group {
                                if let day {
                                    DayDot(
                                        habit: habit,
                                        day: day,
                                        dotSize: dotSize,
                                        checkmarkSize: checkmarkSize,
                                        outlineWidth: todayOutlineWidth
                                    )
                                } else {
                                    // Placeholder to keep grid alignment for leading/trailing non-month days
                                    Color.clear
                                        .frame(width: dotSize, height: dotSize)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .padding(.top, 2)
    }

    // MARK: - Grid generation

    // Returns a 6x7 grid of optional dates for the month containing reference,
    // aligned to calendar.firstWeekday. Non-month leading/trailing slots are nil.
    static func monthGrid(for reference: Date, calendar: Calendar) -> [[Date?]] {
        var cal = calendar
        cal.locale = calendar.locale

        // First day of month
        guard let monthInterval = cal.dateInterval(of: .month, for: reference) else {
            return []
        }
        let firstOfMonth = monthInterval.start
        let startOfMonthDay = cal.startOfDay(for: firstOfMonth)

        // Determine the first displayed day (start of the week containing the 1st)
        let weekday = cal.component(.weekday, from: startOfMonthDay)
        let firstWeekday = cal.firstWeekday
        let deltaToWeekStart = (weekday - firstWeekday + 7) % 7
        let firstDisplayed = cal.date(byAdding: .day, value: -deltaToWeekStart, to: startOfMonthDay) ?? startOfMonthDay

        // We will render 6 rows x 7 columns to cover all months
        var grid: [[Date?]] = []
        var cursor = firstDisplayed

        for _ in 0..<6 {
            var row: [Date?] = []
            for _ in 0..<7 {
                let isInMonth = cal.isDate(cursor, equalTo: startOfMonthDay, toGranularity: .month)
                row.append(isInMonth ? cursor : nil)
                cursor = cal.date(byAdding: .day, value: 1, to: cursor) ?? cursor
            }
            grid.append(row)
        }

        return grid
    }
}

// MARK: - Day Dot

private struct DayDot: View {
    @Environment(\.modelContext) private var context
    @Environment(\.calendar) private var calendar
    
    @Bindable var habit: Habit
    let day: Date
    let dotSize: CGFloat
    let checkmarkSize: CGFloat
    let outlineWidth: CGFloat
    
    var body: some View {
        let isToday = calendar.isDateInToday(day)
        let completionCount = habit.completionCount(on: day, calendar: calendar)
        let completionProgressDouble = habit.completionProgress(on: day, calendar: calendar)
        let completionProgress = CGFloat(completionProgressDouble)
        let isFullyCompleted = habit.isCompleted(on: day, calendar: calendar)
        
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
            
            // Sync habit completion via Watch Connectivity
            SyncManager.shared.syncHabitCompletion(
                habitName: habit.name,
                date: day,
                isCompleted: habit.isCompleted(on: day, calendar: calendar),
                completionCount: habit.completionCount(on: day, calendar: calendar)
            )
            
            #if DEBUG
            // Trigger feedback prompt when 3+ habits completed today
            if !wasDone && habit.isCompleted(on: day, calendar: calendar) && calendar.isDateInToday(day) {
                FeedbackManager.shared.recordCompletion(habit: habit, date: day)
            }
            #endif
        } label: {
            ZStack {
                // Base circle with opacity-based completion indication
                Circle()
                    .fill(completionProgress > 0 ?
                          habit.color.color.opacity(0.3 + (completionProgress * 0.7)) :
                          Color.secondary.opacity(0.15))
                    .frame(width: dotSize, height: dotSize)
                
                // Show checkmark only when fully completed
                if isFullyCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: checkmarkSize, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .overlay {
                if isToday {
                    Circle()
                        .strokeBorder(habit.color.color.opacity(0.9), lineWidth: outlineWidth)
                        .frame(width: dotSize, height: dotSize)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .frame(width: dotSize, height: dotSize)
    }
    
    private var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateStyle = .medium
        let dayString = formatter.string(from: day)
        
        let completionCount = habit.completionCount(on: day, calendar: calendar)
        let target = habit.dailyTarget
        
        if completionCount == 0 {
            return "\(dayString): Not done"
        } else if completionCount >= target {
            return "\(dayString): Complete (\(completionCount)/\(target))"
        } else {
            return "\(dayString): Partial (\(completionCount)/\(target))"
        }
    }
}


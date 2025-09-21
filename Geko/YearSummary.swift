import SwiftUI
import SwiftData
import GekoShared

struct YearSummary: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    
    @Bindable var habit: Habit
    let referenceDate: Date
    
    // Dot sizing: smaller than MonthSummary since we need to fit a full year
    private let dotSize: CGFloat = 8
    private let columnSpacing: CGFloat = 2
    private let rowSpacing: CGFloat = 2
    
    init(habit: Habit, referenceDate: Date = Date()) {
        self.habit = habit
        self.referenceDate = referenceDate
    }
    
    private var yearGrid: [[Date?]] {
        YearSummary.last365DaysGrid(for: referenceDate, calendar: calendar)
    }
    
    private var weekdayHeader: [String] {
        // Use the same single-letter symbol logic as WeekSummary
        let anyWeek = WeekSummary.weekDates(for: referenceDate, calendar: calendar)
        return anyWeek.map { WeekSummary.shortWeekdaySymbol(for: $0, calendar: calendar, locale: locale) }
    }
    
    private var yearTotalDays: Int {
        // For a "last 365 days" view, we can have at most 365 days
        // but might have fewer due to future dates being nil
        yearGrid.flatMap { $0 }.compactMap { $0 }.count
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .trailing, spacing: 4) {
                    // Last 365 days grid: 7 rows (days of week) × ~53 columns (weeks)
                    // Rightmost column is current week, similar to GitHub contribution graph
                    VStack(spacing: rowSpacing) {
                        ForEach(0..<7, id: \.self) { dayOfWeek in
                            HStack(spacing: columnSpacing) {
                                ForEach(0..<yearGrid[dayOfWeek].count, id: \.self) { weekIndex in
                                    let day = yearGrid[dayOfWeek][weekIndex]
                                    Group {
                                        if let day {
                                            YearDot(
                                                habit: habit,
                                                day: day,
                                                dotSize: dotSize
                                            )
                                        } else {
                                            // Placeholder to keep grid alignment
                                            Color.clear
                                                .frame(width: dotSize, height: dotSize)
                                        }
                                    }
                                    .id("week-\(weekIndex)-day-\(dayOfWeek)")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .onAppear {
                // Scroll to the rightmost column (current week) when the view appears
                let lastWeekIndex = yearGrid[0].count - 1
                if lastWeekIndex >= 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("week-\(lastWeekIndex)-day-0", anchor: .trailing)
                        }
                    }
                }
            }
        }
        .padding(.top, 2)
    }
    
    // MARK: - Grid generation
    
    // Returns a grid where each row represents a day of the week (0 = first day of week)
    // and each column represents a week, showing the last ~53 weeks (365+ days)
    // with the rightmost column being the current week (GitHub contribution graph style)
    static func last365DaysGrid(for reference: Date, calendar: Calendar) -> [[Date?]] {
        var cal = calendar
        cal.locale = calendar.locale
        
        // Start from the reference date (typically today)
        let referenceDay = cal.startOfDay(for: reference)
        
        // Find the start of the current week
        let weekday = cal.component(.weekday, from: referenceDay)
        let firstWeekday = cal.firstWeekday
        let deltaToWeekStart = (weekday - firstWeekday + 7) % 7
        let currentWeekStart = cal.date(byAdding: .day, value: -deltaToWeekStart, to: referenceDay) ?? referenceDay
        
        // Go back 52 weeks from the current week to get ~365 days
        // (53 weeks total including current week gives us 371 days)
        let numberOfWeeks = 53
        let firstWeekStart = cal.date(byAdding: .weekOfYear, value: -(numberOfWeeks - 1), to: currentWeekStart) ?? currentWeekStart
        
        // Initialize 7 rows (one for each day of the week)
        var grid: [[Date?]] = Array(repeating: [], count: 7)
        
        // Build the grid week by week, from oldest to newest (left to right)
        var cursor = firstWeekStart
        for _ in 0..<numberOfWeeks {
            for dayOfWeek in 0..<7 {
                let currentDate = cal.date(byAdding: .day, value: dayOfWeek, to: cursor) ?? cursor
                
                // Only include dates that are not in the future
                if currentDate <= referenceDay {
                    grid[dayOfWeek].append(currentDate)
                } else {
                    grid[dayOfWeek].append(nil)
                }
            }
            cursor = cal.date(byAdding: .day, value: 7, to: cursor) ?? cursor
        }
        
        return grid
    }
}

// MARK: - Year Dot

private struct YearDot: View {
    @Environment(\.calendar) private var calendar
    
    @Bindable var habit: Habit
    let day: Date
    let dotSize: CGFloat
    
    var body: some View {
        let isToday = calendar.isDateInToday(day)
        let completionProgress = habit.completionProgress(on: day, calendar: calendar)
        let isFullyCompleted = habit.isCompleted(on: day, calendar: calendar)
        
        // Non-tappable dot with opacity-based completion indication
        RoundedRectangle(cornerRadius: 2)
            .fill(completionProgress > 0 ? 
                  habit.color.color.opacity(0.3 + (completionProgress * 0.7)) : 
                  Color.secondary.opacity(0.1))
            .frame(width: dotSize, height: dotSize)
        .overlay {
            if isToday {
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(habit.color.color.opacity(0.9), lineWidth: 1)
                    .frame(width: dotSize, height: dotSize)
            }
        }
        .accessibilityLabel(accessibilityLabel)
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

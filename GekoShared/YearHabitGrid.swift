import SwiftUI
import SwiftData

// MARK: - YearHabitGrid (Reusable Component)

public struct YearHabitGrid: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    
    @Bindable var habit: Habit
    let referenceDate: Date
    let weekCount: Int
    let dotSize: CGFloat
    let columnSpacing: CGFloat
    let rowSpacing: CGFloat
    let showScrollIndicators: Bool
    
    public init(
        habit: Habit,
        referenceDate: Date = Date(),
        weekCount: Int = 26,
        dotSize: CGFloat = 8,
        columnSpacing: CGFloat = 2,
        rowSpacing: CGFloat = 2,
        showScrollIndicators: Bool = false
    ) {
        self.habit = habit
        self.referenceDate = referenceDate
        self.weekCount = weekCount
        self.dotSize = dotSize
        self.columnSpacing = columnSpacing
        self.rowSpacing = rowSpacing
        self.showScrollIndicators = showScrollIndicators
    }
    
    private var yearGrid: [[Date?]] {
        YearHabitGrid.habitGrid(for: referenceDate, weekCount: weekCount, calendar: calendar)
    }
    
    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: showScrollIndicators) {
                VStack(alignment: .trailing, spacing: 4) {
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
    // and each column represents a week, showing the specified number of weeks
    // with the rightmost column being the current week (GitHub contribution graph style)
    public static func habitGrid(for reference: Date, weekCount: Int, calendar: Calendar) -> [[Date?]] {
        var cal = calendar
        cal.locale = calendar.locale
        
        // Start from the reference date (typically today)
        let referenceDay = cal.startOfDay(for: reference)
        
        // Find the start of the current week
        let weekday = cal.component(.weekday, from: referenceDay)
        let firstWeekday = cal.firstWeekday
        let deltaToWeekStart = (weekday - firstWeekday + 7) % 7
        let currentWeekStart = cal.date(byAdding: .day, value: -deltaToWeekStart, to: referenceDay) ?? referenceDay
        
        // Go back the specified number of weeks from the current week
        let firstWeekStart = cal.date(byAdding: .weekOfYear, value: -(weekCount - 1), to: currentWeekStart) ?? currentWeekStart
        
        // Initialize 7 rows (one for each day of the week)
        var grid: [[Date?]] = Array(repeating: [], count: 7)
        
        // Build the grid week by week, from oldest to newest (left to right)
        var cursor = firstWeekStart
        for _ in 0..<weekCount {
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

public struct YearDot: View {
    @Environment(\.calendar) private var calendar
    
    @Bindable var habit: Habit
    let day: Date
    let dotSize: CGFloat
    
    public init(habit: Habit, day: Date, dotSize: CGFloat) {
        self.habit = habit
        self.day = day
        self.dotSize = dotSize
    }
    
    public var body: some View {
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

import SwiftUI
import SwiftData

// MARK: - YearHabitGrid (Compact version for widgets)

public struct YearHabitGrid: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    
    @Bindable var habit: Habit
    let referenceDate: Date
    let weekCount: Int
    let dotSize: CGFloat
    let columnSpacing: CGFloat
    let rowSpacing: CGFloat
    
    public init(
        habit: Habit,
        referenceDate: Date = Date(),
        weekCount: Int = 26,
        dotSize: CGFloat = 6,
        columnSpacing: CGFloat = 1,
        rowSpacing: CGFloat = 1
    ) {
        self.habit = habit
        self.referenceDate = referenceDate
        self.weekCount = weekCount
        self.dotSize = dotSize
        self.columnSpacing = columnSpacing
        self.rowSpacing = rowSpacing
    }
    
    private var yearGrid: [[Date?]] {
        YearHabitGrid.habitGrid(for: referenceDate, weekCount: weekCount, calendar: calendar)
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let totalWeeks = yearGrid[0].count
            
            // Calculate responsive dot size and spacing
            let spacing = columnSpacing
            let totalSpacing = spacing * CGFloat(max(0, totalWeeks - 1))
            let availableForDots = availableWidth - totalSpacing
            let calculatedDotSize = max(2, availableForDots / CGFloat(totalWeeks))
            
            VStack(spacing: rowSpacing) {
                ForEach(0..<7, id: \.self) { dayOfWeek in
                    HStack(spacing: spacing) {
                        ForEach(0..<yearGrid[dayOfWeek].count, id: \.self) { weekIndex in
                            let day = yearGrid[dayOfWeek][weekIndex]
                            Group {
                                if let day {
                                    YearDot(
                                        habit: habit,
                                        day: day,
                                        dotSize: calculatedDotSize
                                    )
                                } else {
                                    // Placeholder to keep grid alignment
                                    Color.clear
                                        .frame(width: calculatedDotSize, height: calculatedDotSize)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
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

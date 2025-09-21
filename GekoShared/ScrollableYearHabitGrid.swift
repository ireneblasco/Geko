import SwiftUI
import SwiftData

public struct ScrollableYearHabitGrid: View {
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
        weekCount: Int = 53,
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
}

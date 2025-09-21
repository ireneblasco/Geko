import SwiftUI
import SwiftData
import GekoShared

struct YearSummary: View {
    @Bindable var habit: Habit
    let referenceDate: Date
    
    init(habit: Habit, referenceDate: Date = Date()) {
        self.habit = habit
        self.referenceDate = referenceDate
    }
    
    var body: some View {
        ScrollableYearHabitGrid(
            habit: habit,
            referenceDate: referenceDate,
            weekCount: 53, // Keep the original 53 weeks for full year view
            dotSize: 8,
            columnSpacing: 2,
            rowSpacing: 2,
            showScrollIndicators: false
        )
    }
}

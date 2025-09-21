import SwiftUI
import SwiftData
import AudioToolbox
import GekoShared

struct HabitRow: View {
    @Environment(\.modelContext) private var context
    @Bindable var habit: Habit
    let viewMode: ViewMode

    @State private var isPickingEmoji = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Button {
                    isPickingEmoji.toggle()
                } label: {
                    ZStack {
                        Circle()
                            .fill(habit.color.color.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Text(habit.emoji)
                            .font(.system(size: 22))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Change emoji")

                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    let wasDone = habit.isCompleted()
                    
                    if habit.isCompleted() {
                        // If already completed, reset to 0
                        habit.resetCompletion()
                    } else {
                        // If not completed, increment by 1
                        habit.incrementCompletion()
                        // Play sound if this increment completes the habit
                        if !wasDone {
                            SoundFeedback.playCheck()
                        }
                    }
                    
                    try? context.save()
                } label: {
                    ZStack {
                        // Progress ring background
                        Circle()
                            .stroke(habit.color.color.opacity(0.2), lineWidth: 3)
                            .frame(width: 28, height: 28)
                        
                        // Progress ring fill
                        Circle()
                            .trim(from: 0, to: habit.completionProgress())
                            .stroke(habit.color.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 28, height: 28)
                            .rotationEffect(.degrees(-90)) // Start from top
                            .animation(.easeInOut(duration: 0.3), value: habit.completionProgress())
                        
                        // Center icon
                        Image(systemName: habit.isCompleted() ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(habit.isCompleted() ? habit.color.color : .secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .accessibilityLabel(habit.isCompleted() ? "Mark not done" : "Mark done")
                }
                .buttonStyle(.plain)
            }

            switch viewMode {
            case .weekly:
                WeekSummary(habit: habit)
            case .monthly:
                MonthSummary(habit: habit)
            case .yearly:
                YearSummary(habit: habit)
            }
        }
        .padding(.vertical, 6)
        .sheet(isPresented: $isPickingEmoji) {
            EmojiCatalogPicker { picked in
                habit.emoji = String(picked.prefix(1))
                try? context.save()
                isPickingEmoji = false
            } onCancel: {
                isPickingEmoji = false
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var subtitle: String {
        habit.isCompleted() ? "Done today" : "Not done today"
    }
}

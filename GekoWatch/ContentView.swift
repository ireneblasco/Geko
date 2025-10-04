//
//  ContentView.swift
//  GekoWatch
//
//  Created by Irenews on 9/20/25.
//

import SwiftUI
import SwiftData
import GekoShared

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.name, order: .forward) private var habits: [Habit]

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        ForEach(habits) { habit in
                            HabitRowCompact(habit: habit)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Today")
        }
    }
}

private struct EmptyStateView: View {
    @State private var isRefreshing = false
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkerboard.rectangle")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("No Habits Yet")
                .font(.headline)
            Text("Create habits on your iPhone to see them here.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await refreshNow()
                }
            } label: {
                if isRefreshing {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("…")
                    }
                } else {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRefreshing)
            .padding(.top, 6)
        }
        .padding(.horizontal)
    }

    @MainActor
    private func refreshNow() async {
        guard !isRefreshing else { return }
        isRefreshing = true

        // Light haptic to acknowledge tap
        WKInterfaceDevice.current().play(.click)

        // Request full sync via Watch Connectivity or other available methods
        let syncManager = SyncManager.shared
        syncManager.setModelContext(context)
        syncManager.updateSyncStatus()
        syncManager.requestFullSync()
        print("⌚ Watch app manual refresh - sync status: \(syncManager.syncStatusDescription)")

        // Perform a tiny fetch against the shared container to "tickle" the store.
        // This encourages processing of any pending imports and re-evaluates queries.
        do {
            let shared = SharedDataContainer.shared.modelContainer
            let sharedContext = shared.mainContext

            // Minimal fetch
            let fetch = FetchDescriptor<Habit>()
            _ = try sharedContext.fetch(fetch)

            // No-op save on the current model context to ensure changes are visible
            try? context.save()
        } catch {
            // Swallow errors; we only need to nudge the store
            print("⌚ Watch refresh fetch error: \(error)")
        }

        // Small delay to allow UI to re-evaluate @Query
        try? await Task.sleep(nanoseconds: 500_000_000) // Slightly longer for sync
        isRefreshing = false
    }
}

private struct HabitRowCompact: View {
    @Environment(\.modelContext) private var context
    @Bindable var habit: Habit

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(habit.color.color.opacity(0.2))
                    .frame(width: 28, height: 28)
                Text(habit.emoji)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Button {
                toggleProgress()
            } label: {
                ZStack {
                    // Progress ring background
                    Circle()
                        .stroke(habit.color.color.opacity(0.2), lineWidth: 3)
                        .frame(width: 26, height: 26)

                    // Progress ring fill
                    Circle()
                        .trim(from: 0, to: CGFloat(habit.completionProgress()))
                        .stroke(habit.color.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 26, height: 26)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.25), value: habit.completionProgress())

                    // Center icon
                    Image(systemName: habit.isCompleted() ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(habit.isCompleted() ? habit.color.color : .secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .accessibilityLabel(habit.isCompleted() ? "Mark not done" : "Mark done")
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }

    private var subtitle: String {
        let count = habit.completionCount()
        let target = habit.dailyTarget
        if count == 0 {
            return "Not done today"
        } else if count >= target {
            return "Complete (\(count)/\(target))"
        } else {
            return "Progress (\(count)/\(target))"
        }
    }

    private func toggleProgress() {
        if habit.isCompleted() {
            habit.resetCompletion()
        } else {
            habit.incrementCompletion()
        }
        try? context.save()
        
        // Sync habit completion via Watch Connectivity
        let syncManager = SyncManager.shared
        syncManager.syncHabitCompletion(
            habitName: habit.name,
            date: Date(),
            isCompleted: habit.isCompleted(),
            completionCount: habit.completionCount()
        )
        print("⌚ Synced habit completion for '\(habit.name)': \(habit.completionCount())/\(habit.dailyTarget)")
    }
}

// MARK: - Preview Support

private enum PreviewModelContainer {
    @MainActor
    static func make(seed: Bool = true) -> ModelContainer {
        let schema = Schema([Habit.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            if seed {
                let context = container.mainContext

                // Sample habits
                let water = Habit(name: "Drink Water", emoji: "💧", color: .blue, dailyTarget: 8, remindersEnabled: false)
                let read = Habit(name: "Read", emoji: "📚", color: .indigo, dailyTarget: 1, remindersEnabled: false)
                let move = Habit(name: "Move", emoji: "🏃‍♂️", color: .green, dailyTarget: 1, remindersEnabled: false)

                // Seed some progress for today
                // e.g., 3/8 water, read done, move not done
                for _ in 0..<3 { water.incrementCompletion() }
                read.toggleCompleted()

                context.insert(water)
                context.insert(read)
                context.insert(move)

                try? context.save()
            }
            return container
        } catch {
            fatalError("Failed to create in-memory preview container: \(error)")
        }
    }
}

#Preview("Sample Habits") {
    ContentView()
        .modelContainer(PreviewModelContainer.make(seed: true))
}

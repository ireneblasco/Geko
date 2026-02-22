//
//  FeedbackManager.swift
//  Geko
//
//  Manages the in-app feedback prompt that triggers after 3+ habits completed in a day.
//

import Combine
import Foundation
import SwiftData
import SwiftUI
import GekoShared

/// Manages the feedback sheet trigger: shows when user completes 3+ different habits in a day.
@MainActor
public final class FeedbackManager: ObservableObject {
    public static let shared = FeedbackManager()

    private static let feedbackPromptPresentedKey = "feedbackPromptPresented"
    private static let resetFeedbackStateLaunchArg = "--resetFeedbackState"

    @Published public private(set) var shouldShowFeedbackSheet = false

    private var modelContext: ModelContext?
    private let calendar = Calendar.current

    private init() {
        if ProcessInfo.processInfo.arguments.contains(Self.resetFeedbackStateLaunchArg) {
            UserDefaults.standard.removeObject(forKey: Self.feedbackPromptPresentedKey)
        }
    }

    /// Call from the app to provide model context for counting habits.
    public func setModelContext(_ context: ModelContext) {
        modelContext = context
    }

    /// Records a habit completion. Call only when the habit just became completed (not when resetting).
    /// - Parameters:
    ///   - habit: The habit that was completed
    ///   - date: The date of completion (must be today to count toward the trigger)
    public func recordCompletion(habit: Habit, date: Date) {
        guard !hasAskedForFeedback else { return }
        guard calendar.isDateInToday(date) else { return }

        let completedCount = countHabitsCompletedToday()
        guard completedCount > 3 else { return }

        shouldShowFeedbackSheet = true
    }

    /// Call when the feedback sheet is presented (dismissed) so we never ask again.
    public func markSheetPresented() {
        UserDefaults.standard.set(true, forKey: Self.feedbackPromptPresentedKey)
        shouldShowFeedbackSheet = false
    }

    /// Resets the presented flag. Used by tests.
    public func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: Self.feedbackPromptPresentedKey)
        shouldShowFeedbackSheet = false
    }

    /// Forces the feedback sheet to show. For debug only; does not mark as presented.
    public func showFeedbackSheetForDebug() {
        shouldShowFeedbackSheet = true
    }

    private var hasAskedForFeedback: Bool {
        UserDefaults.standard.bool(forKey: Self.feedbackPromptPresentedKey)
    }

    private func countHabitsCompletedToday() -> Int {
        guard let context = modelContext else { return 0 }
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.name)])
        guard let habits = try? context.fetch(descriptor) else { return 0 }
        return habits.filter { $0.isCompleted(on: Date(), calendar: calendar) }.count
    }
}

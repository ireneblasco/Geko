//
//  FeedbackSheetView.swift
//  Geko
//
//  Sheet shown when user completes 3+ habits: enjoy prompt, then review or feedback.
//

import SwiftUI
import StoreKit

struct FeedbackSheetView: View {
    @Environment(\.requestReview) private var requestReview
    @Environment(\.dismiss) private var dismiss

    let onDismiss: () -> Void

    @State private var step: Step = .initial
    @State private var feedbackText = ""
    @State private var isSubmitting = false
    @State private var submitError: String?

    enum Step {
        case initial
        case yesReview
        case noFeedback
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .initial:
                    initialView
                case .yesReview:
                    yesReviewView
                case .noFeedback:
                    noFeedbackView
                }
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismissAndMarkPresented()
                    }
                }
            }
        }
        .accessibilityIdentifier("feedback_sheet")
    }

    private var initialView: some View {
        VStack(spacing: 16) {
            Text("Are you enjoying Geko?")
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.top, 16)

            HStack(spacing: 12) {
                Button("No") {
                    step = .noFeedback
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("feedback_no")

                Button("Yes") {
                    step = .yesReview
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("feedback_yes")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
    }

    private var yesReviewView: some View {
        VStack(spacing: 16) {
            Text("Thanks! Would you leave a review?")
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.top, 16)

            Button("Leave Review") {
                requestReview()
                dismissAndMarkPresented()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
    }

    private var noFeedbackView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("We'd love to hear how we can improve.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("Share your feedback...", text: $feedbackText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
                .accessibilityIdentifier("feedback_textfield")

            if let error = submitError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button {
                submitFeedback()
            } label: {
                if isSubmitting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Submit")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
            .accessibilityIdentifier("feedback_submit")
        }
        .padding(24)
    }

    private func submitFeedback() {
        let text = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isSubmitting = true
        submitError = nil

        Task {
            do {
                try await NotionFeedbackService.shared.submit(feedback: text)
                await MainActor.run {
                    dismissAndMarkPresented()
                }
            } catch {
                await MainActor.run {
                    submitError = "Could not send feedback. Please try again."
                    isSubmitting = false
                }
            }
        }
    }

    private func dismissAndMarkPresented() {
        onDismiss()
        dismiss()
    }
}

#Preview {
    FeedbackSheetView(onDismiss: {})
}

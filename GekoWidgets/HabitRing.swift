import SwiftUI

public struct HabitRing: View {
    public let progress: Double   // 0.0 ... 1.0
    public let color: Color
    public let emoji: String
    public let size: CGFloat
    public let lineWidth: CGFloat
    public var animated: Bool
    
    public init(
        progress: Double,
        color: Color,
        emoji: String,
        size: CGFloat = 32,
        lineWidth: CGFloat = 2.5,
        animated: Bool = false
    ) {
        self.progress = max(0, min(1, progress))
        self.color = color
        self.emoji = emoji
        self.size = size
        self.lineWidth = lineWidth
        self.animated = animated
    }
    
    public var body: some View {
        ZStack {
            // Progress ring background
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress ring fill
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(animated ? .easeInOut(duration: 0.3) : .none, value: progress)
            
            // Emoji in center
            Text(emoji)
                .font(.system(size: size * 0.56)) // 18 for 32, scales with size
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Habit progress")
        .accessibilityValue("\(Int(round(progress * 100))) percent")
    }
}


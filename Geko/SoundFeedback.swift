import Foundation
import AudioToolbox
#if os(iOS)
import UIKit
#endif

enum SoundFeedback {
    private static let systemSoundID: SystemSoundID = 1104

    static func playCheck() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
        AudioServicesPlaySystemSound(systemSoundID)
    }
}

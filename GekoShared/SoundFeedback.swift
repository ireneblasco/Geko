import Foundation
#if os(iOS)
import AudioToolbox
import UIKit
#endif

public enum SoundFeedback {
    #if os(iOS)
    private static let systemSoundID: SystemSoundID = 1104
    #endif
    
    public static func playCheck() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        AudioServicesPlaySystemSound(systemSoundID)
        #endif
    }
}

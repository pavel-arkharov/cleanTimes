import Foundation

#if os(iOS)
import UIKit
#endif

@MainActor
enum MeditationWakeLock {
    static func setActive(_ isActive: Bool) {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = isActive
        #endif
    }
}

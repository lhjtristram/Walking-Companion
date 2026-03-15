import Foundation

/// Keys used in WatchConnectivity messages and application context.
enum WatchMessage {
    // Real-time metric update (phone → watch, 1 Hz during walk)
    static let metricsKey = "walkMetrics"

    // Walk control commands (bidirectional)
    static let startWalkKey = "startWalk"
    static let stopWalkKey = "stopWalk"
    static let pauseWalkKey = "pauseWalk"

    // Settings sync (phone → watch)
    static let cadenceTargetKey = "cadenceTarget"

    // Alert (phone → watch: trigger haptic)
    static let cadenceAlertKey = "cadenceAlert"

    // Media controls (watch → phone)
    static let mediaCommandKey  = "mediaCommand"
    static let mediaPlayPause   = "playPause"
    static let mediaSkipNext    = "skipNext"
    static let mediaSkipPrevious = "skipPrevious"
}

/// Media control commands sent from Watch → iPhone via WatchConnectivity.
enum MediaCommand: String {
    case playPause, skipNext, skipPrevious
}

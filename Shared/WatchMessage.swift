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
}

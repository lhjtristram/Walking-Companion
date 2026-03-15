import Foundation

/// Live metrics transmitted between iPhone and Apple Watch during an active walk.
struct WalkMetrics: Codable, Sendable, Equatable {
    var duration: TimeInterval = 0       // seconds elapsed
    var steps: Int = 0
    var cadence: Int = 0                 // steps per minute
    var distance: Double = 0            // metres
    var pace: Double = 0                // seconds per kilometre (0 = unavailable)
    var heartRate: Double = 0           // bpm — populated by watch
    var calories: Double = 0
    var isActive: Bool = false
    var liveScore: Int = 0               // real-time Cadence Score (0–100), updated every tick

    /// Human-readable pace string, e.g. "5:42 /km"
    var paceString: String {
        guard pace > 0 else { return "--:-- /km" }
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }

    /// Distance formatted for display, e.g. "2.4 km" or "450 m"
    var distanceString: String {
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        } else {
            return String(format: "%.0f m", distance)
        }
    }

    /// Duration formatted as MM:SS or H:MM:SS
    var durationString: String {
        let total = Int(duration)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
}

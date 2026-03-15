import Foundation
import SwiftData

@Model
final class WalkSession {
    var id: UUID
    var startDate: Date
    var endDate: Date
    var duration: TimeInterval         // seconds
    var steps: Int
    var distance: Double               // metres
    var averageCadence: Int            // steps per minute
    var averagePace: Double            // seconds per kilometre
    var calories: Double
    var averageHeartRate: Double       // bpm (0 if unavailable)
    var cadenceTarget: Int             // target set at start of walk
    var alertsFired: Int               // how many cadence alerts fired

    // Cadence Score fields
    var cadenceScore: Int              // 0–100 performance score for this walk
    var minutesAtCadence: Double       // total minutes at or above target cadence
    var percentAtCadence: Double       // % of walk at or above target cadence (0–100)

    init(
        startDate: Date,
        endDate: Date,
        duration: TimeInterval,
        steps: Int,
        distance: Double,
        averageCadence: Int,
        averagePace: Double,
        calories: Double,
        averageHeartRate: Double,
        cadenceTarget: Int,
        alertsFired: Int,
        cadenceScore: Int = 0,
        minutesAtCadence: Double = 0,
        percentAtCadence: Double = 0
    ) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.steps = steps
        self.distance = distance
        self.averageCadence = averageCadence
        self.averagePace = averagePace
        self.calories = calories
        self.averageHeartRate = averageHeartRate
        self.cadenceTarget = cadenceTarget
        self.alertsFired = alertsFired
        self.cadenceScore = cadenceScore
        self.minutesAtCadence = minutesAtCadence
        self.percentAtCadence = percentAtCadence
    }

    var distanceString: String {
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        } else {
            return String(format: "%.0f m", distance)
        }
    }

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

    var paceString: String {
        guard averagePace > 0 else { return "--:-- /km" }
        let minutes = Int(averagePace) / 60
        let seconds = Int(averagePace) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }

    /// Letter grade derived from cadenceScore.
    var scoreGrade: String {
        switch cadenceScore {
        case 90...100: return "A"
        case 75..<90:  return "B"
        case 60..<75:  return "C"
        case 45..<60:  return "D"
        default:       return "F"
        }
    }
}

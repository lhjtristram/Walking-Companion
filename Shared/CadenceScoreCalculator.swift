import Foundation

/// Input snapshot used to compute a Cadence Score for a completed (or in-progress) walk.
struct CadenceScoreInput {
    let ticksAtTarget: Int        // ticks where cadence >= target
    let ticksAboveTarget: Int     // ticks where cadence strictly > target
    let totalActiveTicks: Int     // total non-paused ticks recorded
    let cadenceReadings: [Int]    // one reading per active tick (steps/min)
    let cadenceTarget: Int        // the user's target cadence for this walk
}

/// Calculates a 0–100 Cadence Score from three weighted components:
///
/// | Component            | Weight | Meaning                                   |
/// |----------------------|--------|-------------------------------------------|
/// | Time at target       |  50 %  | % of walk at or above target cadence      |
/// | Cadence stability    |  30 %  | Inverse of cadence variance               |
/// | Time above target    |  20 %  | % of walk exceeding target cadence        |
enum CadenceScoreCalculator {

    static func calculate(_ input: CadenceScoreInput) -> Int {
        guard input.totalActiveTicks > 0, input.cadenceTarget > 0 else { return 0 }

        // --- Component 1: % time at target (weight 0.50) ---
        let atTargetPct = Double(input.ticksAtTarget) / Double(input.totalActiveTicks) * 100.0
        let score1 = atTargetPct * 0.50

        // --- Component 2: Stability (weight 0.30) ---
        // Uses coefficient of variation relative to target to penalise wild swings.
        // stdDev/target * 200 → at 50% CV the stability score hits 0.
        let stability = cadenceStability(readings: input.cadenceReadings, target: input.cadenceTarget)
        let score2 = stability * 0.30

        // --- Component 3: % time above target (weight 0.20) ---
        let aboveTargetPct = Double(input.ticksAboveTarget) / Double(input.totalActiveTicks) * 100.0
        let score3 = aboveTargetPct * 0.20

        let total = score1 + score2 + score3
        return min(100, max(0, Int(total.rounded())))
    }

    /// Returns a 0–100 stability score. Perfect consistency = 100; high variance approaches 0.
    static func cadenceStability(readings: [Int], target: Int) -> Double {
        guard readings.count > 1, target > 0 else { return 100 }

        let mean = Double(readings.reduce(0, +)) / Double(readings.count)
        let variance = readings.reduce(0.0) { $0 + pow(Double($1) - mean, 2) } / Double(readings.count)
        let stdDev = sqrt(variance)

        // Coefficient of variation expressed against the target (not the mean),
        // so a walker who is consistently fast still gets a good stability score.
        let cv = stdDev / Double(target) * 100.0
        return max(0.0, 100.0 - cv * 2.0)
    }

    /// Partial score using a running set of readings — used for the live score during a walk.
    static func liveScore(from input: CadenceScoreInput) -> Int {
        calculate(input)
    }
}

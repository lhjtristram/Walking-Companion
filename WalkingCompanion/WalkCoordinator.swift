import Foundation
import SwiftData
import Observation

/// Orchestrates an active walk session across CadenceService, WorkoutService, and LocationService.
/// Publishes a live WalkMetrics snapshot consumed by both views and WatchConnector.
@MainActor
@Observable
final class WalkCoordinator {
    private(set) var metrics = WalkMetrics()
    private(set) var isWalking = false
    private(set) var isPaused = false

    private let cadence: CadenceService
    private let workout: WorkoutService
    private let location: LocationService
    private let connector: WatchConnector

    private var timer: Timer?
    private var startDate: Date?
    private var pausedDuration: TimeInterval = 0
    private var pauseStart: Date?

    // Cadence Score tracking (reset each walk)
    private var cadenceReadings: [Int] = []
    private var ticksAtTarget: Int = 0
    private var ticksAboveTarget: Int = 0
    private var totalActiveTicks: Int = 0
    private var walkCadenceTarget: Int = 110   // captured at walk start

    init(
        cadence: CadenceService,
        workout: WorkoutService,
        location: LocationService,
        connector: WatchConnector
    ) {
        self.cadence = cadence
        self.workout = workout
        self.location = location
        self.connector = connector

        // Forward watch commands
        connector.onStartWalkFromWatch = { [weak self] in
            Task { try? await self?.start(settings: UserSettings()) }
        }
        connector.onStopWalkFromWatch = { [weak self] in
            Task { await self?.stop(context: nil) }
        }

        // Forward cadence alerts to watch
        NotificationCenter.default.addObserver(
            forName: .cadenceAlertFired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.connector.sendCadenceAlert()
        }
    }

    // MARK: — Walk lifecycle

    func start(settings: UserSettings) async throws {
        guard !isWalking else { return }

        startDate = Date()
        pausedDuration = 0
        metrics = WalkMetrics(isActive: true)
        isWalking = true
        isPaused = false

        // Reset score tracking
        cadenceReadings = []
        ticksAtTarget = 0
        ticksAboveTarget = 0
        totalActiveTicks = 0
        walkCadenceTarget = settings.cadenceTarget

        cadence.start(settings: settings)
        location.start()
        try workout.startWorkout()
        connector.sendCadenceTarget(settings.cadenceTarget)

        // 1 Hz metric aggregation + watch sync
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func pause() {
        guard isWalking, !isPaused else { return }
        isPaused = true
        pauseStart = Date()
        workout.pauseWorkout()
    }

    func resume() {
        guard isWalking, isPaused else { return }
        if let ps = pauseStart {
            pausedDuration += Date().timeIntervalSince(ps)
        }
        isPaused = false
        pauseStart = nil
        workout.resumeWorkout()
    }

    func stop(context: ModelContext?) async {
        guard isWalking else { return }

        timer?.invalidate()
        timer = nil

        let alertsFired = cadence.stop()
        location.stop()
        await workout.stopWorkout()

        metrics.isActive = false
        isWalking = false
        isPaused = false

        // Compute final Cadence Score
        let scoreInput = CadenceScoreInput(
            ticksAtTarget: ticksAtTarget,
            ticksAboveTarget: ticksAboveTarget,
            totalActiveTicks: totalActiveTicks,
            cadenceReadings: cadenceReadings,
            cadenceTarget: walkCadenceTarget
        )
        let finalScore = CadenceScoreCalculator.calculate(scoreInput)
        let minutesAt = Double(ticksAtTarget) / 60.0
        let pctAt = totalActiveTicks > 0
            ? Double(ticksAtTarget) / Double(totalActiveTicks) * 100.0
            : 0.0

        // Persist session
        if let context, let startDate {
            let session = WalkSession(
                startDate: startDate,
                endDate: Date(),
                duration: metrics.duration,
                steps: metrics.steps,
                distance: metrics.distance,
                averageCadence: metrics.cadence,
                averagePace: metrics.pace,
                calories: metrics.calories,
                averageHeartRate: metrics.heartRate,
                cadenceTarget: walkCadenceTarget,     // fixed: was incorrectly storing metrics.cadence
                alertsFired: alertsFired,
                cadenceScore: finalScore,
                minutesAtCadence: minutesAt,
                percentAtCadence: pctAt
            )
            context.insert(session)
            try? context.save()
        }
    }

    // MARK: — Private

    private func tick() {
        guard let startDate else { return }

        let elapsed = Date().timeIntervalSince(startDate) - pausedDuration
        metrics.duration = elapsed
        metrics.steps = cadence.currentSteps
        metrics.cadence = cadence.currentCadence
        metrics.distance = location.distance
        metrics.pace = location.pace
        metrics.calories = workout.calories
        metrics.isActive = isWalking && !isPaused

        // Accumulate Cadence Score data (only while not paused)
        if !isPaused {
            let c = cadence.currentCadence
            cadenceReadings.append(c)
            totalActiveTicks += 1
            if c >= walkCadenceTarget { ticksAtTarget += 1 }
            if c > walkCadenceTarget  { ticksAboveTarget += 1 }

            // Update live score in metrics (sent to watch each tick)
            let input = CadenceScoreInput(
                ticksAtTarget: ticksAtTarget,
                ticksAboveTarget: ticksAboveTarget,
                totalActiveTicks: totalActiveTicks,
                cadenceReadings: cadenceReadings,
                cadenceTarget: walkCadenceTarget
            )
            metrics.liveScore = CadenceScoreCalculator.liveScore(from: input)
        }

        connector.send(metrics: metrics)
    }
}

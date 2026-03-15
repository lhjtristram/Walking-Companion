import Foundation
import HealthKit
import Observation

/// Manages a HealthKit workout session so the walk continues tracking in the background.
@MainActor
@Observable
final class WorkoutService: NSObject {
    private(set) var isActive: Bool = false
    private(set) var calories: Double = 0

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var startDate: Date?

    static var isHealthKitAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: — Permissions

    func requestPermissions() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let types: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.stepCount),
            HKQuantityType(.heartRate)
        ]

        try await store.requestAuthorization(toShare: types, read: types)
    }

    // MARK: — Session lifecycle

    func startWorkout() throws {
        let config = HKWorkoutConfiguration()
        config.activityType = .walking
        config.locationType = .outdoor

        let newSession = try HKWorkoutSession(healthStore: store, configuration: config)
        let newBuilder = newSession.associatedWorkoutBuilder()

        newBuilder.dataSource = HKLiveWorkoutDataSource(
            healthStore: store,
            workoutConfiguration: config
        )

        newSession.delegate = self
        newBuilder.delegate = self

        self.session = newSession
        self.builder = newBuilder
        self.startDate = Date()

        newSession.startActivity(with: startDate!)
        newBuilder.beginCollection(withStart: startDate!) { _, _ in }

        isActive = true
    }

    func stopWorkout() async {
        guard let session, let builder else { return }

        session.end()
        let endDate = Date()

        do {
            try await builder.endCollection(at: endDate)
            try await builder.finishWorkout()
        } catch {
            print("WorkoutService: failed to finish workout — \(error)")
        }

        isActive = false
        self.session = nil
        self.builder = nil
    }

    func pauseWorkout() {
        session?.pause()
    }

    func resumeWorkout() {
        session?.resume()
    }
}

// MARK: — HKWorkoutSessionDelegate

extension WorkoutService: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        // State changes handled via builder delegate
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        print("WorkoutService: session error — \(error)")
    }
}

// MARK: — HKLiveWorkoutBuilderDelegate

extension WorkoutService: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        Task { @MainActor in
            if collectedTypes.contains(HKQuantityType(.activeEnergyBurned)),
               let stat = workoutBuilder.statistics(for: HKQuantityType(.activeEnergyBurned)) {
                self.calories = stat.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            }
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}

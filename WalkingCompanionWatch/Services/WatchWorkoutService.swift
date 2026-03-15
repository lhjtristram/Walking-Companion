import Foundation
import HealthKit
import WatchKit
import Observation

/// Mirrors the HKWorkoutSession on the watch so heart rate and other watch-only
/// metrics (e.g. from wrist sensors) are captured and available.
@MainActor
@Observable
final class WatchWorkoutService: NSObject {
    private(set) var heartRate: Double = 0
    private(set) var isActive: Bool = false

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    func requestPermissions() async throws {
        let types: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKQuantityType(.heartRate),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning)
        ]
        try await store.requestAuthorization(toShare: types, read: types)
    }

    func startWorkout() throws {
        let config = HKWorkoutConfiguration()
        config.activityType = .walking
        config.locationType = .outdoor

        let newSession = try HKWorkoutSession(healthStore: store, configuration: config)
        let newBuilder = newSession.associatedWorkoutBuilder()
        newBuilder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
        newSession.delegate = self
        newBuilder.delegate = self

        self.session = newSession
        self.builder = newBuilder

        let now = Date()
        newSession.startActivity(with: now)
        newBuilder.beginCollection(withStart: now) { _, _ in }
        isActive = true
    }

    func stopWorkout() async {
        session?.end()
        do {
            try await builder?.endCollection(at: Date())
            try await builder?.finishWorkout()
        } catch {
            print("WatchWorkoutService: finish error — \(error)")
        }
        isActive = false
        session = nil
        builder = nil
    }
}

// MARK: — HKWorkoutSessionDelegate

extension WatchWorkoutService: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {}

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        print("WatchWorkoutService: session error — \(error)")
    }
}

// MARK: — HKLiveWorkoutBuilderDelegate

extension WatchWorkoutService: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        Task { @MainActor in
            if collectedTypes.contains(HKQuantityType(.heartRate)),
               let stat = workoutBuilder.statistics(for: HKQuantityType(.heartRate)) {
                let bpm = stat.mostRecentQuantity()?.doubleValue(for: .count().unitDivided(by: .minute()))
                self.heartRate = bpm ?? 0
            }
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}

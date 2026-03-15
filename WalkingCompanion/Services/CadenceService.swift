import Foundation
import CoreMotion
import AVFoundation
import Observation

/// Streams real-time cadence from CMPedometer and fires coaching alerts.
@MainActor
@Observable
final class CadenceService {
    private(set) var currentCadence: Int = 0
    private(set) var currentSteps: Int = 0
    private(set) var isAlertActive: Bool = false

    private let pedometer = CMPedometer()
    private var alertTimer: Timer?
    private var alertsFiredCount: Int = 0
    private var settings: UserSettings?
    private var synthesizer = AVSpeechSynthesizer()

    static var isCadenceAvailable: Bool {
        CMPedometer.isCadenceAvailable() && CMPedometer.isStepCountingAvailable()
    }

    // MARK: — Public API

    func start(settings: UserSettings) {
        self.settings = settings
        alertsFiredCount = 0
        isAlertActive = false

        guard CMPedometer.isStepCountingAvailable() else { return }

        pedometer.startUpdates(from: Date()) { [weak self] data, error in
            guard let self, let data, error == nil else { return }
            Task { @MainActor in
                self.currentSteps = data.numberOfSteps.intValue

                // CMPedometerData.currentCadence is steps/second — multiply by 60
                if let cadence = data.currentCadence {
                    self.currentCadence = Int((cadence.doubleValue * 60).rounded())
                    self.evaluateCadence()
                }
            }
        }
    }

    func stop() -> Int {
        pedometer.stopUpdates()
        cancelAlertTimer()
        currentCadence = 0
        currentSteps = 0
        isAlertActive = false
        let count = alertsFiredCount
        alertsFiredCount = 0
        return count
    }

    // MARK: — Private

    private func evaluateCadence() {
        guard let settings else { return }

        if currentCadence < settings.cadenceTarget {
            // Start grace-period timer if not already running
            if alertTimer == nil {
                alertTimer = Timer.scheduledTimer(
                    withTimeInterval: settings.graceInterval,
                    repeats: false
                ) { [weak self] _ in
                    Task { @MainActor in self?.fireAlert() }
                }
            }
        } else {
            // Back on pace — cancel pending alert
            cancelAlertTimer()
            isAlertActive = false
        }
    }

    private func fireAlert() {
        guard let settings else { return }
        alertsFiredCount += 1
        isAlertActive = true
        alertTimer = nil  // clear so it can fire again after next grace period

        switch settings.alertType {
        case .hapticOnly:
            // Haptic is triggered on iPhone via UIFeedbackGenerator in the view layer
            NotificationCenter.default.post(name: .cadenceAlertFired, object: nil)

        case .voiceOnly:
            speakAlert(settings: settings)

        case .hapticAndVoice:
            NotificationCenter.default.post(name: .cadenceAlertFired, object: nil)
            speakAlert(settings: settings)
        }
    }

    private func speakAlert(settings: UserSettings) {
        let text = "Pick up your pace. Target cadence: \(settings.cadenceTarget) steps per minute."
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 0.9
        synthesizer.speak(utterance)
    }

    private func cancelAlertTimer() {
        alertTimer?.invalidate()
        alertTimer = nil
    }
}

extension Notification.Name {
    static let cadenceAlertFired = Notification.Name("cadenceAlertFired")
}

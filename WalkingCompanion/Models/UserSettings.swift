import Foundation
import Observation

/// Persisted user preferences. Stored in UserDefaults.
@Observable
final class UserSettings {
    // MARK: — Cadence coaching
    var cadenceTarget: Int {
        didSet { UserDefaults.standard.set(cadenceTarget, forKey: Keys.cadenceTarget) }
    }
    var graceInterval: TimeInterval {
        didSet { UserDefaults.standard.set(graceInterval, forKey: Keys.graceInterval) }
    }
    var alertType: AlertType {
        didSet { UserDefaults.standard.set(alertType.rawValue, forKey: Keys.alertType) }
    }

    // MARK: — Audio
    var autoPlayOnWalkStart: Bool {
        didSet { UserDefaults.standard.set(autoPlayOnWalkStart, forKey: Keys.autoPlay) }
    }

    // MARK: — Init
    init() {
        let defaults = UserDefaults.standard
        cadenceTarget = defaults.integer(forKey: Keys.cadenceTarget).nonZero ?? 110
        graceInterval = defaults.double(forKey: Keys.graceInterval).nonZero ?? 10
        alertType = AlertType(rawValue: defaults.string(forKey: Keys.alertType) ?? "") ?? .hapticAndVoice
        autoPlayOnWalkStart = defaults.bool(forKey: Keys.autoPlay)
    }

    // MARK: — Types
    enum AlertType: String, CaseIterable, Identifiable {
        case hapticOnly = "haptic"
        case voiceOnly = "voice"
        case hapticAndVoice = "hapticAndVoice"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .hapticOnly: return "Haptic only"
            case .voiceOnly: return "Voice only"
            case .hapticAndVoice: return "Haptic + Voice"
            }
        }
    }

    private enum Keys {
        static let cadenceTarget = "cadenceTarget"
        static let graceInterval = "graceInterval"
        static let alertType = "alertType"
        static let autoPlay = "autoPlay"
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}

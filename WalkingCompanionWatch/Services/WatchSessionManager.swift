import Foundation
import WatchConnectivity
import Observation

/// Manages the Watch side of WatchConnectivity.
/// Receives live WalkMetrics from the iPhone and forwards control commands back.
@MainActor
@Observable
final class WatchSessionManager: NSObject {
    private(set) var metrics = WalkMetrics()
    private(set) var isConnected: Bool = false
    private(set) var cadenceTarget: Int = 110
    var onCadenceAlert: (() -> Void)?

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: — Sending commands to phone

    func sendStartWalk() {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage([WatchMessage.startWalkKey: true], replyHandler: nil)
    }

    func sendStopWalk() {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage([WatchMessage.stopWalkKey: true], replyHandler: nil)
    }

    func sendMediaCommand(_ command: MediaCommand) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(
            [WatchMessage.mediaCommandKey: command.rawValue],
            replyHandler: nil
        )
    }
}

// MARK: — WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.isConnected = session.isReachable
            // Restore cadence target from last application context
            if let target = session.receivedApplicationContext[WatchMessage.cadenceTargetKey] as? Int {
                self.cadenceTarget = target
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in self.isConnected = session.isReachable }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            // Live metrics update
            if let data = message[WatchMessage.metricsKey] as? Data,
               let decoded = try? JSONDecoder().decode(WalkMetrics.self, from: data) {
                self.metrics = decoded
            }

            // Cadence alert — trigger haptic
            if message[WatchMessage.cadenceAlertKey] != nil {
                self.onCadenceAlert?()
            }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        Task { @MainActor in
            if let target = applicationContext[WatchMessage.cadenceTargetKey] as? Int {
                self.cadenceTarget = target
            }
        }
    }
}

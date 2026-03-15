import Foundation
import WatchConnectivity
import Observation

/// Manages the iPhone side of WatchConnectivity.
/// Sends live WalkMetrics to the watch and receives commands (start/stop) from the watch.
@MainActor
@Observable
final class WatchConnector: NSObject {
    private(set) var isWatchReachable: Bool = false

    var onStartWalkFromWatch: (() -> Void)?
    var onStopWalkFromWatch: (() -> Void)?

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: — Sending data

    func send(metrics: WalkMetrics) {
        guard WCSession.default.isReachable else { return }

        do {
            let data = try JSONEncoder().encode(metrics)
            WCSession.default.sendMessage(
                [WatchMessage.metricsKey: data],
                replyHandler: nil,
                errorHandler: { error in
                    print("WatchConnector: send error — \(error)")
                }
            )
        } catch {
            print("WatchConnector: encode error — \(error)")
        }
    }

    func sendCadenceTarget(_ target: Int) {
        guard WCSession.default.activationState == .activated else { return }
        try? WCSession.default.updateApplicationContext(
            [WatchMessage.cadenceTargetKey: target]
        )
    }

    func sendCadenceAlert() {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(
            [WatchMessage.cadenceAlertKey: true],
            replyHandler: nil,
            errorHandler: nil
        )
    }
}

// MARK: — WCSessionDelegate

extension WatchConnector: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.isWatchReachable = session.isReachable
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchReachable = session.isReachable
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            if message[WatchMessage.startWalkKey] != nil {
                self.onStartWalkFromWatch?()
            } else if message[WatchMessage.stopWalkKey] != nil {
                self.onStopWalkFromWatch?()
            }
        }
    }
}

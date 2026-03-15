import SwiftUI
import WatchKit

struct MainWatchView: View {
    @Environment(WatchSessionManager.self) private var session
    @Environment(WatchWorkoutService.self) private var workoutService

    @State private var flashAlert = false

    var body: some View {
        if session.metrics.isActive {
            ActiveWatchView(flashAlert: $flashAlert)
        } else {
            IdleWatchView()
        }
    }
}

// MARK: — Idle screen (walk not started)

struct IdleWatchView: View {
    @Environment(WatchSessionManager.self) private var session

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.walk")
                .font(.system(size: 40))
                .foregroundStyle(.green)

            Text("Walking\nCompanion")
                .font(.headline)
                .multilineTextAlignment(.center)

            Button("Start Walk") {
                session.sendStartWalk()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)

            if !session.isConnected {
                Text("No iPhone")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

// MARK: — Active walk screen

struct ActiveWatchView: View {
    @Environment(WatchSessionManager.self) private var session
    @Environment(WatchWorkoutService.self) private var workoutService
    @Binding var flashAlert: Bool

    var metrics: WalkMetrics { session.metrics }
    var isOnTarget: Bool { metrics.cadence >= session.cadenceTarget }

    var body: some View {
        TabView {
            cadenceTab
            statsTab
            controlTab
        }
        .background(flashAlert ? Color.orange.opacity(0.3) : Color.clear)
        .animation(.easeOut(duration: 0.4), value: flashAlert)
        .onReceive(NotificationCenter.default.publisher(for: .watchCadenceAlert)) { _ in
            WKInterfaceDevice.current().play(.notification)
            flashAlert = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { flashAlert = false }
        }
        .onAppear {
            session.onCadenceAlert = {
                NotificationCenter.default.post(name: .watchCadenceAlert, object: nil)
            }
        }
    }

    // Tab 1: Big cadence display
    private var cadenceTab: some View {
        VStack(spacing: 2) {
            Text("\(metrics.cadence)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(isOnTarget ? .green : .orange)
                .monospacedDigit()

            Text("spm")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Image(systemName: isOnTarget ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(isOnTarget ? .green : .orange)
                .font(.caption)

            Text("Target: \(session.cadenceTarget)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // Tab 2: Secondary stats
    private var statsTab: some View {
        VStack(spacing: 6) {
            WatchStatRow(label: "Time",  value: metrics.durationString)
            WatchStatRow(label: "Dist",  value: metrics.distanceString)
            WatchStatRow(label: "Pace",  value: metrics.paceString)
            WatchStatRow(label: "Score", value: "\(metrics.liveScore)")
            if workoutService.heartRate > 0 {
                WatchStatRow(label: "HR", value: "\(Int(workoutService.heartRate)) bpm")
            }
        }
        .padding(.horizontal, 4)
    }

    // Tab 3: Controls
    private var controlTab: some View {
        VStack(spacing: 8) {
            Button("Stop Walk") {
                session.sendStopWalk()
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .font(.caption)
        }
    }
}

// MARK: — Shared row

private struct WatchStatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)
            Text(value)
                .font(.system(.body, design: .rounded).bold())
                .monospacedDigit()
        }
    }
}

extension Notification.Name {
    static let watchCadenceAlert = Notification.Name("watchCadenceAlert")
}

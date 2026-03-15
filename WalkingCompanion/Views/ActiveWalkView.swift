import SwiftUI
import SwiftData
import UIKit

struct ActiveWalkView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(WalkCoordinator.self) private var coordinator
    @Environment(UserSettings.self) private var settings

    @State private var showStopConfirm = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top row: Duration + live score pill
                ZStack(alignment: .topTrailing) {
                    Text(coordinator.metrics.durationString)
                        .font(.system(size: 72, weight: .thin, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .frame(maxWidth: .infinity)

                    LiveScorePill(score: coordinator.metrics.liveScore)
                        .padding(.top, 16)
                        .padding(.trailing, 16)
                }
                .padding(.top, 40)

                // Cadence with target indicator
                CadenceMeter(
                    current: coordinator.metrics.cadence,
                    target: settings.cadenceTarget
                )
                .padding(.top, 24)

                // Stats row
                HStack(spacing: 0) {
                    StatCell(label: "Distance", value: coordinator.metrics.distanceString)
                    Divider().frame(height: 44).background(.white.opacity(0.2))
                    StatCell(label: "Pace", value: coordinator.metrics.paceString)
                    Divider().frame(height: 44).background(.white.opacity(0.2))
                    StatCell(label: "Steps", value: "\(coordinator.metrics.steps)")
                }
                .padding(.top, 32)

                Spacer()

                // Controls
                HStack(spacing: 32) {
                    Button {
                        if coordinator.isPaused { coordinator.resume() }
                        else { coordinator.pause() }
                    } label: {
                        Image(systemName: coordinator.isPaused ? "play.fill" : "pause.fill")
                            .font(.title2)
                            .frame(width: 56, height: 56)
                            .background(.white.opacity(0.15))
                            .clipShape(Circle())
                            .foregroundStyle(.white)
                    }

                    Button {
                        showStopConfirm = true
                    } label: {
                        Text("Stop")
                            .font(.headline)
                            .frame(width: 120, height: 56)
                            .background(.red.opacity(0.8))
                            .clipShape(Capsule())
                            .foregroundStyle(.white)
                    }
                }
                .padding(.bottom, 48)
            }
        }
        .confirmationDialog("End this walk?", isPresented: $showStopConfirm, titleVisibility: .visible) {
            Button("End Walk", role: .destructive) {
                Task { await coordinator.stop(context: modelContext) }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onReceive(NotificationCenter.default.publisher(for: .cadenceAlertFired)) { _ in
            // Haptic feedback on iPhone
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }
}

// MARK: — Sub-views

private struct CadenceMeter: View {
    let current: Int
    let target: Int

    private var isOnTarget: Bool { current >= target }
    private var diff: Int { current - target }
    private var color: Color { isOnTarget ? .green : .orange }

    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(current)")
                    .font(.system(size: 96, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
                Text("spm")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.6))
            }

            HStack(spacing: 6) {
                Image(systemName: isOnTarget ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .foregroundStyle(color)
                Text(isOnTarget
                     ? "+\(diff) above target"
                     : "\(abs(diff)) below target (\(target) spm)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
}

private struct LiveScorePill: View {
    let score: Int

    private var color: Color {
        switch score {
        case 75...100: return .green
        case 50..<75:  return .yellow
        default:       return .orange
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption2)
            Text("\(score)")
                .font(.caption.bold())
                .monospacedDigit()
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.2))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
    }
}

private struct StatCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

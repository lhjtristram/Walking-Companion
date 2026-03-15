import SwiftUI
import MapKit

struct SessionDetailView: View {
    let session: WalkSession

    var body: some View {
        List {
            // --- Cadence Score ---
            Section {
                HStack(spacing: 24) {
                    ScoreRingView(score: session.cadenceScore)
                        .frame(width: 100, height: 100)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text("Grade \(session.scoreGrade)")
                                .font(.title2.bold())
                                .foregroundStyle(gradeColor(session.scoreGrade))
                            Text("\(session.cadenceScore) / 100")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }

                        ScoreBreakdownRow(label: "At target",    value: String(format: "%.0f%%", session.percentAtCadence),              weight: "50%")
                        ScoreBreakdownRow(label: "Stability",    value: "—",                                                             weight: "30%")
                        ScoreBreakdownRow(label: "Above target", value: String(format: "%.0f%%", max(0, session.percentAtCadence - 50)), weight: "20%")
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Cadence Score")
            }

            // --- Summary ---
            Section("Summary") {
                StatRow(label: "Distance",      value: session.distanceString,                           icon: "figure.walk")
                StatRow(label: "Duration",      value: session.durationString,                           icon: "clock")
                StatRow(label: "Avg Pace",      value: session.paceString,                               icon: "speedometer")
                StatRow(label: "Avg Cadence",   value: "\(session.averageCadence) spm",                  icon: "metronome")
                StatRow(label: "Steps",         value: "\(session.steps)",                               icon: "shoeprints.fill")
                StatRow(label: "Calories",      value: String(format: "%.0f kcal", session.calories),    icon: "flame")
                if session.averageHeartRate > 0 {
                    StatRow(label: "Avg Heart Rate", value: "\(Int(session.averageHeartRate)) bpm",      icon: "heart")
                }
            }

            // --- Coaching ---
            Section("Coaching") {
                StatRow(label: "Cadence Target",   value: "\(session.cadenceTarget) spm",                        icon: "target")
                StatRow(label: "Time at Cadence",  value: String(format: "%.1f min", session.minutesAtCadence),  icon: "timer")
                StatRow(label: "% at Cadence",     value: String(format: "%.0f%%", session.percentAtCadence),    icon: "chart.bar")
                StatRow(label: "Alerts Fired",     value: "\(session.alertsFired)",                              icon: "bell")
            }
        }
        .navigationTitle("Walk Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "A": return .green
        case "B": return .blue
        case "C": return .yellow
        case "D": return .orange
        default:  return .red
        }
    }
}

// MARK: — Score Ring (also used by InsightsView)

struct ScoreRingView: View {
    let score: Int

    private var fraction: Double { Double(score) / 100.0 }

    var ringColor: Color {
        switch score {
        case 75...100: return .green
        case 50..<75:  return .yellow
        case 25..<50:  return .orange
        default:       return .red
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(ringColor.opacity(0.15), lineWidth: 10)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.5), value: score)

            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(ringColor)
                    .monospacedDigit()
                Text("score")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: — Sub-views

private struct ScoreBreakdownRow: View {
    let label: String
    let value: String
    let weight: String

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)
            Text(value)
                .font(.caption.bold())
            Spacer()
            Text(weight)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

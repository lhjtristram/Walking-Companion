import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \WalkSession.startDate, order: .reverse) private var sessions: [WalkSession]

    private var last30: [WalkSession] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        return sessions.filter { $0.startDate >= cutoff }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No data yet",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Complete walks to see your trends.")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            levelCard
                            summaryCards
                            scoreChart
                            cadenceChart
                            distanceChart
                            frequencyChart
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Insights")          // used as back-button label if we push views
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: — Sections

    // Level card — shows current level, icon, and progress to next
    private var levelCard: some View {
        let currentLevel = CadenceLevel.earned(from: Array(sessions))
        let progress = currentLevel.progressToNext(from: Array(sessions))
        let nextLevel = currentLevel.next

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: currentLevel.icon)
                    .font(.title2)
                    .foregroundStyle(currentLevel.color)
                    .frame(width: 40, height: 40)
                    .background(currentLevel.color.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(currentLevel.displayName)
                        .font(.headline)
                        .foregroundStyle(currentLevel.color)
                    Text(currentLevel.requirement)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if sessions.count >= 1 {
                    Text("Level \(currentLevel.rawValue + 1)")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(currentLevel.color.opacity(0.15))
                        .foregroundStyle(currentLevel.color)
                        .clipShape(Capsule())
                }
            }

            if let next = nextLevel {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Next: \(next.displayName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: progress)
                        .tint(next.color)
                }
            } else {
                Text("Max level reached!")
                    .font(.caption.bold())
                    .foregroundStyle(.purple)
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            InsightCard(
                title: "Walks (30d)",
                value: "\(last30.count)",
                icon: "figure.walk",
                color: .green
            )
            InsightCard(
                title: "Avg Score",
                value: last30.isEmpty ? "--"
                    : "\(Int(last30.map(\.cadenceScore).average))",
                icon: "star.fill",
                color: .blue
            )
            InsightCard(
                title: "Total Distance",
                value: totalDistance,
                icon: "map",
                color: .orange
            )
        }
    }

    private var totalDistance: String {
        let m = last30.map(\.distance).reduce(0, +)
        return m >= 1000 ? String(format: "%.1f km", m / 1000) : String(format: "%.0f m", m)
    }

    private var scoreChart: some View {
        let scored = last30.filter { $0.cadenceScore > 0 }
        return ChartCard(title: "Cadence Score (last 30 days)") {
            Chart(scored) { session in
                LineMark(
                    x: .value("Date", session.startDate),
                    y: .value("Score", session.cadenceScore)
                )
                .foregroundStyle(.purple)
                PointMark(
                    x: .value("Date", session.startDate),
                    y: .value("Score", session.cadenceScore)
                )
                .foregroundStyle(.purple)
            }
            .chartYScale(domain: 0...100)
            .chartYAxisLabel("Score")
        }
    }

    private var cadenceChart: some View {
        ChartCard(title: "Cadence (last 30 days)") {
            Chart(last30) { session in
                LineMark(
                    x: .value("Date", session.startDate),
                    y: .value("spm", session.averageCadence)
                )
                .foregroundStyle(.blue)
                PointMark(
                    x: .value("Date", session.startDate),
                    y: .value("spm", session.averageCadence)
                )
                .foregroundStyle(.blue)
            }
            .chartYAxisLabel("spm")
        }
    }

    private var distanceChart: some View {
        ChartCard(title: "Distance per walk") {
            Chart(last30) { session in
                BarMark(
                    x: .value("Date", session.startDate),
                    y: .value("km", session.distance / 1000)
                )
                .foregroundStyle(.green.gradient)
            }
            .chartYAxisLabel("km")
        }
    }

    private var frequencyChart: some View {
        ChartCard(title: "Weekly walks") {
            let weekly = weeklyFrequency(from: last30)
            Chart(weekly, id: \.week) { item in
                BarMark(
                    x: .value("Week", item.week),
                    y: .value("Walks", item.count)
                )
                .foregroundStyle(.orange.gradient)
            }
        }
    }

    private struct WeekCount {
        let week: String
        let count: Int
    }

    private func weeklyFrequency(from sessions: [WalkSession]) -> [WeekCount] {
        let cal = Calendar.current
        var map: [Date: Int] = [:]
        for session in sessions {
            let week = cal.dateInterval(of: .weekOfYear, for: session.startDate)?.start ?? session.startDate
            map[week, default: 0] += 1
        }
        return map.sorted { $0.key < $1.key }.map { key, value in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return WeekCount(week: formatter.string(from: key), count: value)
        }
    }
}

// MARK: — Helpers

private struct InsightCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct ChartCard<Content: View>: View {
    let title: String
    @ViewBuilder let chart: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            chart()
                .frame(height: 160)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private extension [Int] {
    var average: Double {
        guard !isEmpty else { return 0 }
        return Double(reduce(0, +)) / Double(count)
    }
}

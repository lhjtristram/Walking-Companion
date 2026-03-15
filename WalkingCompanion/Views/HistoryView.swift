import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \WalkSession.startDate, order: .reverse) private var sessions: [WalkSession]

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No walks yet",
                        systemImage: "figure.walk",
                        description: Text("Start your first walk to see it here.")
                    )
                } else {
                    List(sessions) { session in
                        NavigationLink {
                            SessionDetailView(session: session)
                        } label: {
                            SessionRow(session: session)
                        }
                    }
                }
            }
            .navigationTitle("History")           // used as back-button label in SessionDetailView
            .toolbar(.hidden, for: .navigationBar) // hide at root; shows when pushed
        }
    }
}

// Shared row used by HomeView + HistoryView
struct SessionRow: View {
    let session: WalkSession

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Self.dateFormatter.string(from: session.startDate))
                .font(.subheadline.bold())

            HStack(spacing: 16) {
                Label(session.distanceString, systemImage: "figure.walk")
                Label(session.durationString, systemImage: "clock")
                Label("\(session.averageCadence) spm", systemImage: "metronome")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

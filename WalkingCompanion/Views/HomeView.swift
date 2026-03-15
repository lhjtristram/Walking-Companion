import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(WalkCoordinator.self) private var coordinator
    @Environment(UserSettings.self) private var settings

    @Query(sort: \WalkSession.startDate, order: .reverse) private var sessions: [WalkSession]

    @State private var isStartingWalk = false
    @State private var startError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if coordinator.isWalking {
                    ActiveWalkView()
                        .transition(.opacity)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            startButton
                            cadenceCard
                            if !sessions.isEmpty { recentCard }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Walking Companion")
            .navigationBarTitleDisplayMode(.large)
            .alert("Couldn't start walk", isPresented: .constant(startError != nil)) {
                Button("OK") { startError = nil }
            } message: {
                Text(startError ?? "")
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.isWalking)
    }

    // MARK: — Sections

    private var startButton: some View {
        Button {
            startWalk()
        } label: {
            HStack {
                Image(systemName: "figure.walk")
                    .font(.title2)
                Text("Start Walk")
                    .font(.title3.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(.green)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isStartingWalk)
    }

    private var cadenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Cadence Target", systemImage: "metronome")
                .font(.headline)

            HStack {
                Text("\(settings.cadenceTarget)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text("spm")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                Spacer()
                Stepper("", value: Bindable(settings).cadenceTarget, in: 80...160, step: 5)
                    .labelsHidden()
            }

            NavigationLink("Coaching settings →") {
                CoachingSettingsView()
            }
            .font(.subheadline)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Recent Walks", systemImage: "clock")
                    .font(.headline)
                Spacer()
                NavigationLink("See all") {
                    HistoryView()
                }
                .font(.subheadline)
            }

            ForEach(sessions.prefix(3)) { session in
                NavigationLink {
                    SessionDetailView(session: session)
                } label: {
                    SessionRow(session: session)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: — Actions

    private func startWalk() {
        isStartingWalk = true
        Task {
            do {
                try await coordinator.start(settings: settings)
            } catch {
                startError = error.localizedDescription
            }
            isStartingWalk = false
        }
    }
}

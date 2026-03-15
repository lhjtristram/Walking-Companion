import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(WalkCoordinator.self) private var coordinator
    @Environment(UserSettings.self) private var settings

    @Query(sort: \WalkSession.startDate, order: .reverse) private var sessions: [WalkSession]

    @State private var isStartingWalk = false
    @State private var startError: String?

    // Gradient used for the app icon and card border
    private let brandGradient = LinearGradient(
        colors: [.green, .teal, .blue, .purple, .orange, .yellow],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        NavigationStack {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            if coordinator.isWalking {
                ActiveWalkView()
                    .transition(.opacity)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        appHeader
                        cadenceCard
                        startButton
                        if !sessions.isEmpty { recentCard }
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.isWalking)
        .alert("Couldn't start walk", isPresented: .constant(startError != nil)) {
            Button("OK") { startError = nil }
        } message: {
            Text(startError ?? "")
        }
        } // NavigationStack
    }

    // MARK: — Header

    private var appHeader: some View {
        HStack(spacing: 12) {
            // App icon
            ZStack {
                Circle()
                    .fill(brandGradient)
                    .frame(width: 52, height: 52)
                Image(systemName: "figure.walk")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text("Walking Companion")
                .font(.title2.bold())

            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: — Sections

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
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(brandGradient, lineWidth: 2)
        )
    }

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

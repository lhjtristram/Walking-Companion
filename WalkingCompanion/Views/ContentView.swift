import SwiftUI

struct ContentView: View {
    @Environment(WalkCoordinator.self) private var coordinator
    @State private var selectedTab: AppTab = .home

    enum AppTab: CaseIterable {
        case home, audio, history, insights

        var label: String {
            switch self {
            case .home:     "Home"
            case .audio:    "Audio"
            case .history:  "History"
            case .insights: "Insights"
            }
        }

        var icon: String {
            switch self {
            case .home:     "house.fill"
            case .audio:    "music.note"
            case .history:  "clock.fill"
            case .insights: "chart.line.uptrend.xyaxis"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── Page content ────────────────────────────────────────
            Group {
                switch selectedTab {
                case .home:     HomeView()
                case .audio:    AudioView()
                case .history:  HistoryView()
                case .insights: InsightsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Give content room above the floating tab bar
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 80)
            }

            // ── Floating pill tab bar ────────────────────────────────
            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.label) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: .medium))
                            Text(tab.label)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(selectedTab == tab ? .blue : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedTab == tab
                                ? Color.blue.opacity(0.12)
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
            .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 4)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .ignoresSafeArea(edges: .bottom)
        .task {
            try? await WorkoutService().requestPermissions()
            LocationService().requestPermissions()
        }
    }
}

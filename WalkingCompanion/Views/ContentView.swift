import SwiftUI

struct ContentView: View {
    @Environment(WalkCoordinator.self) private var coordinator

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }

            AudioView()
                .tabItem { Label("Audio", systemImage: "music.note.list") }

            HistoryView()
                .tabItem { Label("History", systemImage: "clock") }

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.line.uptrend.xyaxis") }
        }
        .task {
            // Request all permissions on first launch
            try? await WorkoutService().requestPermissions()
            LocationService().requestPermissions()
        }
    }
}

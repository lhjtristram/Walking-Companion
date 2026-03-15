import SwiftUI

@main
struct WalkingCompanionWatchApp: App {
    @State private var sessionManager = WatchSessionManager()
    @State private var workoutService = WatchWorkoutService()

    var body: some Scene {
        WindowGroup {
            TabView {
                MainWatchView()
                    .tabItem { Label("Walk", systemImage: "figure.walk") }

                AudioControlView()
                    .tabItem { Label("Audio", systemImage: "music.note") }
            }
            .environment(sessionManager)
            .environment(workoutService)
            .task {
                try? await workoutService.requestPermissions()
            }
        }
    }
}

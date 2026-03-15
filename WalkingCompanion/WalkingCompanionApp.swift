import SwiftUI
import SwiftData
import UIKit

@main
struct WalkingCompanionApp: App {
    // Services
    private let settings = UserSettings()
    private let cadenceService = CadenceService()
    private let workoutService = WorkoutService()
    private let locationService = LocationService()
    private let watchConnector = WatchConnector()
    private let musicService = MusicService()
    private let podcastManager = PodcastManager()

    // Coordinator wires the services together
    @State private var coordinator: WalkCoordinator

    init() {
        let cadence = CadenceService()
        let workout = WorkoutService()
        let location = LocationService()
        let connector = WatchConnector()
        _coordinator = State(initialValue: WalkCoordinator(
            cadence: cadence,
            workout: workout,
            location: location,
            connector: connector
        ))
    }

    var body: some Scene {
        WindowGroup {
            // Outer ZStack ensures the backing UIKit window area is always
            // filled with the app colour — never the wallpaper / black.
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea(.all)

                ContentView()
                    .environment(settings)
                    .environment(coordinator)
                    .environment(musicService)
                    .environment(podcastManager)
            }
            .task {
                // Belt-and-suspenders: also set the UIKit window's own
                // backgroundColor so any pixel the SwiftUI layer doesn't
                // reach is still grey, not transparent/black.
                UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap(\.windows)
                    .forEach { $0.backgroundColor = .systemGroupedBackground }
            }
        }
        .modelContainer(for: WalkSession.self)
    }
}

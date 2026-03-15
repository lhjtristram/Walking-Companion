import SwiftUI
import SwiftData

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
            ContentView()
                .environment(settings)
                .environment(coordinator)
                .environment(musicService)
                .environment(podcastManager)
        }
        .modelContainer(for: WalkSession.self)
    }
}

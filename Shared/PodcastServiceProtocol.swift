import Foundation
import Combine

/// Abstraction over any podcast source (RSS, Spotify, etc.).
/// Add new services by conforming to this protocol — no changes needed in views.
@MainActor
protocol PodcastServiceProtocol: ObservableObject {
    var sourceName: String { get }
    var isAvailable: Bool { get }
    var nowPlaying: PodcastEpisode? { get }
    var isPlaying: Bool { get }

    func search(query: String) async throws -> [PodcastShow]
    func episodes(for show: PodcastShow) async throws -> [PodcastEpisode]
    func play(episode: PodcastEpisode)
    func pause()
    func resume()
    func stop()
}

/// Type-erased wrapper so different service types can live in an array.
@MainActor
final class AnyPodcastService: ObservableObject {
    let sourceName: String

    private let _isAvailable: () -> Bool
    private let _nowPlaying: () -> PodcastEpisode?
    private let _isPlaying: () -> Bool
    private let _search: (String) async throws -> [PodcastShow]
    private let _episodes: (PodcastShow) async throws -> [PodcastEpisode]
    private let _play: (PodcastEpisode) -> Void
    private let _pause: () -> Void
    private let _resume: () -> Void
    private let _stop: () -> Void

    var isAvailable: Bool { _isAvailable() }
    var nowPlaying: PodcastEpisode? { _nowPlaying() }
    var isPlaying: Bool { _isPlaying() }

    init<S: PodcastServiceProtocol>(_ service: S) {
        sourceName = service.sourceName
        _isAvailable = { service.isAvailable }
        _nowPlaying = { service.nowPlaying }
        _isPlaying = { service.isPlaying }
        _search = { try await service.search(query: $0) }
        _episodes = { try await service.episodes(for: $0) }
        _play = { service.play(episode: $0) }
        _pause = { service.pause() }
        _resume = { service.resume() }
        _stop = { service.stop() }
    }

    func search(query: String) async throws -> [PodcastShow] {
        try await _search(query)
    }

    func episodes(for show: PodcastShow) async throws -> [PodcastEpisode] {
        try await _episodes(show)
    }

    func play(episode: PodcastEpisode) { _play(episode) }
    func pause() { _pause() }
    func resume() { _resume() }
    func stop() { _stop() }
}

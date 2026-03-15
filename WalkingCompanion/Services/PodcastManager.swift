import Foundation
import Observation

/// Aggregates all podcast services. Views talk to PodcastManager, not individual services.
/// To add a new service: instantiate it below and append to `services`.
@MainActor
@Observable
final class PodcastManager {
    let rss = RSSPodcastService()
    let spotify = SpotifyPodcastService()

    private(set) var searchResults: [(show: PodcastShow, service: String)] = []
    private(set) var isSearching = false
    private(set) var activeEpisode: PodcastEpisode?
    private(set) var isPlaying: Bool = false

    // MARK: — Unified search across all available services

    func search(query: String) async {
        isSearching = true
        searchResults = []
        defer { isSearching = false }

        await withTaskGroup(of: [(PodcastShow, String)].self) { group in
            group.addTask {
                let shows = (try? await self.rss.search(query: query)) ?? []
                return shows.map { ($0, self.rss.sourceName) }
            }

            if spotify.isAvailable {
                group.addTask {
                    let shows = (try? await self.spotify.search(query: query)) ?? []
                    return shows.map { ($0, self.spotify.sourceName) }
                }
            }

            for await results in group {
                searchResults.append(contentsOf: results)
            }
        }
    }

    func episodes(for show: PodcastShow) async throws -> [PodcastEpisode] {
        switch show.source {
        case .rss: return try await rss.episodes(for: show)
        case .spotify: return try await spotify.episodes(for: show)
        }
    }

    func play(episode: PodcastEpisode) {
        // Stop currently playing service before switching
        stopAll()

        switch episode.source {
        case .rss: rss.play(episode: episode)
        case .spotify: spotify.play(episode: episode)
        }

        activeEpisode = episode
        isPlaying = true
    }

    func pauseResume() {
        guard let episode = activeEpisode else { return }
        if isPlaying {
            service(for: episode)?.pause()
            isPlaying = false
        } else {
            service(for: episode)?.resume()
            isPlaying = true
        }
    }

    func stop() {
        stopAll()
        activeEpisode = nil
        isPlaying = false
    }

    // MARK: — Private

    private func stopAll() {
        rss.stop()
        spotify.stop()
    }

    private func service(for episode: PodcastEpisode) -> (any _BasicPodcastControl)? {
        switch episode.source {
        case .rss: return rss
        case .spotify: return spotify
        }
    }
}

/// Minimal protocol for pause/resume control without the full generic protocol overhead.
private protocol _BasicPodcastControl {
    func pause()
    func resume()
    func stop()
}
extension RSSPodcastService: _BasicPodcastControl {}
extension SpotifyPodcastService: _BasicPodcastControl {}

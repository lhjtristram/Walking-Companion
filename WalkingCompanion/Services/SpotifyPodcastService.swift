import Foundation
import Observation

/// Spotify podcast service using the SpotifyiOS SDK (remote control via Spotify app).
///
/// SETUP REQUIRED before this compiles:
/// 1. Register your app at https://developer.spotify.com/dashboard
/// 2. Set your Client ID and Redirect URI below
/// 3. Add the SpotifyiOS SDK via Swift Package Manager:
///    https://github.com/spotify/ios-sdk
/// 4. Add URL scheme to Info.plist: LSApplicationQueriesSchemes → spotify
/// 5. Add your redirect URI scheme to CFBundleURLTypes
///
/// Until the SDK is added, this file compiles but all operations are no-ops.
@MainActor
@Observable
final class SpotifyPodcastService {
    // MARK: — Configuration (fill these in)
    static let clientID = "YOUR_SPOTIFY_CLIENT_ID"
    static let redirectURI = "walkingcompanion://spotify-callback"

    private(set) var nowPlaying: PodcastEpisode?
    private(set) var isPlaying: Bool = false
    private(set) var isConnected: Bool = false

    let sourceName = "Spotify"

    /// Returns true only if the Spotify app is installed.
    var isAvailable: Bool {
        guard let spotifyURL = URL(string: "spotify:") else { return false }
        return UIApplication.shared.canOpenURL(spotifyURL)
    }

    // MARK: — Auth

    /// Call this to initiate Spotify OAuth. The callback is handled in your App's
    /// openURL scene delegate via SpotifyAppRemote.
    func connect() {
        // SPTConfiguration + SPTAppRemote setup goes here once the SDK is linked.
        // See: https://developer.spotify.com/documentation/ios
        print("SpotifyPodcastService: SDK not yet linked — see file header for setup steps.")
    }

    func disconnect() {
        isConnected = false
        nowPlaying = nil
        isPlaying = false
    }

    // MARK: — Search

    func search(query: String) async throws -> [PodcastShow] {
        guard isConnected else { return [] }
        // Use SPTAppRemote + Spotify Web API to search for podcasts.
        // Requires Bearer token from OAuth flow.
        // Returns [] until SDK is wired up.
        return []
    }

    func episodes(for show: PodcastShow) async throws -> [PodcastEpisode] {
        guard isConnected else { return [] }
        return []
    }

    // MARK: — Playback (remote control via Spotify app)

    func play(episode: PodcastEpisode) {
        guard isConnected, let url = episode.audioURL else { return }
        // SPTAppRemote.playerAPI?.play(url.absoluteString, callback: ...)
        nowPlaying = episode
        isPlaying = true
    }

    func pause() {
        // SPTAppRemote.playerAPI?.pause(...)
        isPlaying = false
    }

    func resume() {
        // SPTAppRemote.playerAPI?.resume(...)
        isPlaying = true
    }

    func stop() {
        pause()
        nowPlaying = nil
    }
}

// Silence UIApplication import warning in non-UIKit contexts
#if canImport(UIKit)
import UIKit
#endif

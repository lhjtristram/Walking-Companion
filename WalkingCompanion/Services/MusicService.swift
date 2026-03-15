import Foundation
import MusicKit
import Observation

@MainActor
@Observable
final class MusicService {
    private(set) var authorizationStatus: MusicAuthorization.Status = .notDetermined
    private(set) var recentPlaylists: [Playlist] = []
    private(set) var nowPlayingTitle: String?
    private(set) var nowPlayingArtist: String?
    private(set) var nowPlayingArtwork: Artwork?
    private(set) var currentPlaylistID: MusicItemID?
    private(set) var isPlaying: Bool = false
    private(set) var isLoading: Bool = false
    private(set) var loadError: String?

    private let player = ApplicationMusicPlayer.shared

    init() {
        authorizationStatus = MusicAuthorization.currentStatus
    }

    // MARK: — Permissions

    func requestPermissions() async {
        authorizationStatus = await MusicAuthorization.request()
        if authorizationStatus == .authorized {
            await loadRecentPlaylists()
        }
    }

    // MARK: — Library

    /// Idempotent — only loads if authorised and not already loaded.
    func loadIfNeeded() async {
        guard authorizationStatus == .authorized,
              recentPlaylists.isEmpty,
              !isLoading else { return }
        await loadRecentPlaylists()
    }

    func loadRecentPlaylists() async {
        isLoading = true
        loadError = nil
        do {
            var request = MusicLibraryRequest<Playlist>()
            request.limit = 50
            let response = try await request.response()
            recentPlaylists = Array(response.items)
            if recentPlaylists.isEmpty {
                loadError = "No playlists found in your Apple Music library."
            }
        } catch {
            loadError = error.localizedDescription
            print("MusicService: playlist load error — \(error)")
        }
        isLoading = false
    }

    // MARK: — Playback

    func play(playlist: Playlist) async {
        guard authorizationStatus == .authorized else { return }
        do {
            player.queue = [playlist]
            try await player.play()
            currentPlaylistID = playlist.id
            updateNowPlaying()
        } catch {
            print("MusicService: play error — \(error)")
        }
    }

    func playPause() async {
        if isPlaying {
            player.pause()
        } else {
            do { try await player.play() } catch {}
        }
        updateNowPlaying()
    }

    func skipNext() async {
        do { try await player.skipToNextEntry() } catch {}
        updateNowPlaying()
    }

    func skipPrevious() async {
        // Restart current track — graceful fallback when no previous entry exists
        player.playbackTime = 0
        if !isPlaying {
            do { try await player.play() } catch {}
        }
        updateNowPlaying()
    }

    // MARK: — State sync
    // Called by the view's polling task every second so track title / artwork
    // stay current even when the playlist advances automatically.

    func updateNowPlaying() {
        if let entry = player.queue.currentEntry {
            nowPlayingTitle  = entry.title
            nowPlayingArtist = entry.subtitle
            nowPlayingArtwork = entry.artwork
        } else {
            nowPlayingTitle   = nil
            nowPlayingArtist  = nil
            nowPlayingArtwork = nil
        }
        isPlaying = player.state.playbackStatus == .playing
    }
}

import Foundation
import MusicKit
import Observation

@MainActor
@Observable
final class MusicService {
    private(set) var authorizationStatus: MusicAuthorization.Status = .notDetermined
    private(set) var recentPlaylists: [Playlist] = []
    private(set) var nowPlayingTitle: String?
    private(set) var isPlaying: Bool = false

    private let player = ApplicationMusicPlayer.shared

    // MARK: — Permissions

    func requestPermissions() async {
        authorizationStatus = await MusicAuthorization.request()
        if authorizationStatus == .authorized {
            await loadRecentPlaylists()
        }
    }

    // MARK: — Library

    func loadRecentPlaylists() async {
        do {
            var request = MusicLibraryRequest<Playlist>()
            request.limit = 25
            let response = try await request.response()
            recentPlaylists = Array(response.items)
        } catch {
            print("MusicService: playlist load error — \(error)")
        }
    }

    // MARK: — Playback

    func play(playlist: Playlist) async {
        guard authorizationStatus == .authorized else { return }
        do {
            player.queue = [playlist]
            try await player.play()
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

    // MARK: — Private

    private func updateNowPlaying() {
        if let entry = player.queue.currentEntry {
            nowPlayingTitle = entry.title
        }
        isPlaying = player.state.playbackStatus == .playing
    }
}

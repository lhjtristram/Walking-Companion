import SwiftUI
import MusicKit

struct AudioView: View {
    @Environment(MusicService.self) private var musicService
    @Environment(PodcastManager.self) private var podcasts

    @State private var selectedTab: AudioTab = .music

    enum AudioTab: String, CaseIterable {
        case music = "Music"
        case podcasts = "Podcasts"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    ForEach(AudioTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedTab {
                case .music:    MusicTabView()
                case .podcasts: PodcastTabView()
                }
            }
            .navigationTitle("Audio")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: — Music tab

private struct MusicTabView: View {
    @Environment(MusicService.self) private var musicService

    var body: some View {
        Group {
            switch musicService.authorizationStatus {
            case .authorized:
                authorizedView
            case .notDetermined:
                AuthPromptView(message: "Allow access to your Apple Music library.") {
                    await musicService.requestPermissions()
                }
            default:
                ContentUnavailableView("Apple Music Unavailable", systemImage: "music.note")
            }
        }
    }

    // MARK: Authorized state

    @ViewBuilder
    private var authorizedView: some View {
        if musicService.isLoading {
            ProgressView("Loading playlists…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        } else if let error = musicService.loadError {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                Text(error)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button("Try Again") {
                    Task { await musicService.loadRecentPlaylists() }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        } else {
            ScrollView {
                LazyVStack(spacing: 16) {

                    // ── Now Playing card ─────────────────────────────
                    if musicService.nowPlayingTitle != nil {
                        NowPlayingCard()
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // ── Library ──────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Library")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            ForEach(
                                Array(musicService.recentPlaylists.enumerated()),
                                id: \.element.id
                            ) { index, playlist in
                                PlaylistRow(playlist: playlist)
                                if index < musicService.recentPlaylists.count - 1 {
                                    Divider().padding(.leading, 78)
                                }
                            }
                        }
                        .background(.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
                .animation(.easeInOut, value: musicService.nowPlayingTitle != nil)
            }
        }
    }
}

// MARK: — Now Playing card

private struct NowPlayingCard: View {
    @Environment(MusicService.self) private var musicService

    var body: some View {
        VStack(spacing: 20) {

            // Artwork
            Group {
                if let artwork = musicService.nowPlayingArtwork {
                    ArtworkImage(artwork, width: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 260, height: 260)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 80, weight: .ultraLight))
                                .foregroundStyle(.white.opacity(0.7))
                        )
                }
            }
            .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 8)
            .frame(maxWidth: .infinity, alignment: .center)

            // Title + artist
            VStack(alignment: .leading, spacing: 4) {
                Text(musicService.nowPlayingTitle ?? "")
                    .font(.title3.bold())
                    .lineLimit(1)
                if let artist = musicService.nowPlayingArtist {
                    Text(artist)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Transport controls  ⏮  ⏯  ⏭
            HStack(spacing: 48) {
                Button {
                    Task { await musicService.skipPrevious() }
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title)
                }

                Button {
                    Task { await musicService.playPause() }
                } label: {
                    Image(systemName: musicService.isPlaying
                          ? "pause.circle.fill"
                          : "play.circle.fill")
                        .font(.system(size: 64))
                }

                Button {
                    Task { await musicService.skipNext() }
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title)
                }
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(20)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        // Poll every second so title/artwork updates when the playlist auto-advances
        .task {
            while !Task.isCancelled {
                musicService.updateNowPlaying()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
}

// MARK: — Playlist row

private struct PlaylistRow: View {
    @Environment(MusicService.self) private var musicService
    let playlist: Playlist

    var body: some View {
        Button {
            Task { await musicService.play(playlist: playlist) }
        } label: {
            HStack(spacing: 12) {
                // Playlist artwork
                if let artwork = playlist.artwork {
                    ArtworkImage(artwork, width: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.quaternary)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "music.note.list")
                                .foregroundStyle(.secondary)
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(playlist.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if let desc = playlist.standardDescription {
                        Text(desc)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if musicService.currentPlaylistID == playlist.id {
                    Image(systemName: musicService.isPlaying
                          ? "speaker.wave.2.fill"
                          : "speaker.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        // Refresh after tapping so the playing indicator appears immediately
        .task { musicService.updateNowPlaying() }
    }
}

// MARK: — Podcast tab

private struct PodcastTabView: View {
    @Environment(PodcastManager.self) private var podcasts
    @State private var query = ""
    @State private var selectedShow: PodcastShow?

    var body: some View {
        VStack {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search podcasts", text: $query)
                    .submitLabel(.search)
                    .onSubmit { Task { await podcasts.search(query: query) } }
            }
            .padding(10)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)

            // Now playing bar
            if let episode = podcasts.activeEpisode {
                NowPlayingBar(episode: episode, isPlaying: podcasts.isPlaying) {
                    podcasts.pauseResume()
                }
            }

            // Results
            if podcasts.isSearching {
                ProgressView().padding()
                Spacer()
            } else if query.isEmpty {
                ContentUnavailableView(
                    "Search Podcasts",
                    systemImage: "mic",
                    description: Text("Find shows from Apple Podcasts and Spotify.")
                )
            } else if podcasts.searchResults.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                List(podcasts.searchResults, id: \.show.id) { item in
                    NavigationLink {
                        EpisodeListView(show: item.show)
                    } label: {
                        ShowRow(show: item.show, source: item.service)
                    }
                }
            }
        }
    }
}

// MARK: — Podcast sub-views

private struct ShowRow: View {
    let show: PodcastShow
    let source: String

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: show.artworkURL) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: 8).fill(.quaternary)
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(show.title)
                    .font(.body)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(show.author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(source)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

private struct EpisodeListView: View {
    let show: PodcastShow
    @Environment(PodcastManager.self) private var podcasts
    @State private var episodes: [PodcastEpisode] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading episodes…")
            } else if let error {
                ContentUnavailableView(error, systemImage: "exclamationmark.triangle")
            } else {
                List(episodes) { episode in
                    Button {
                        podcasts.play(episode: episode)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(episode.title)
                                .font(.body)
                                .lineLimit(2)
                            HStack {
                                if episode.duration > 0 {
                                    Text(formatDuration(episode.duration))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if let date = episode.publishedAt {
                                    Text(date, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle(show.title)
        .task {
            do {
                episodes = try await podcasts.episodes(for: show)
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func formatDuration(_ d: TimeInterval) -> String {
        let m = Int(d) / 60
        return m >= 60 ? "\(m / 60)h \(m % 60)m" : "\(m)m"
    }
}

private struct NowPlayingBar: View {
    let episode: PodcastEpisode
    let isPlaying: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(episode.title)
                    .font(.caption.bold())
                    .lineLimit(1)
            }
            Spacer()
            Button(action: onToggle) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

private struct AuthPromptView: View {
    let message: String
    let action: () async -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Allow Access") {
                Task { await action() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

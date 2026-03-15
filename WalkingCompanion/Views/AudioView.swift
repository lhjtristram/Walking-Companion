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
                case .music: MusicTabView()
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
                AuthPromptView(message: "Allow access to your Apple Music library.", action: {
                    await musicService.requestPermissions()
                })
            default:
                ContentUnavailableView("Apple Music Unavailable", systemImage: "music.note")
            }
        }
    }

    private var authorizedView: some View {
        Group {
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
                List(musicService.recentPlaylists, id: \.id) { playlist in
                    Button {
                        Task { await musicService.play(playlist: playlist) }
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(playlist.name)
                                    .font(.body)
                                if let desc = playlist.standardDescription {
                                    Text(desc)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                            if musicService.nowPlayingTitle == playlist.name {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .task { await musicService.loadIfNeeded() }
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

// MARK: — Sub-views

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

import Foundation
import AVFoundation
import Observation

/// Podcast service backed by iTunes Search API (discovery) + RSS (episodes) + AVPlayer (playback).
/// Covers ~95% of public podcasts with no API key or user account required.
@MainActor
@Observable
final class RSSPodcastService: NSObject {
    private(set) var nowPlaying: PodcastEpisode?
    private(set) var isPlaying: Bool = false

    private var player: AVPlayer?
    private var playerObserver: NSKeyValueObservation?

    let sourceName = "Podcasts"
    var isAvailable: Bool { true }     // always available

    // MARK: — Search (iTunes Search API)

    func search(query: String) async throws -> [PodcastShow] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }

        var components = URLComponents(string: "https://itunes.apple.com/search")!
        components.queryItems = [
            URLQueryItem(name: "media", value: "podcast"),
            URLQueryItem(name: "term", value: query),
            URLQueryItem(name: "limit", value: "20")
        ]

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let result = try JSONDecoder().decode(iTunesSearchResult.self, from: data)

        return result.results.compactMap { item in
            guard let feedURL = item.feedUrl.flatMap(URL.init) else { return nil }
            return PodcastShow(
                id: String(item.collectionId),
                title: item.collectionName ?? "Unknown",
                author: item.artistName ?? "",
                description: "",
                artworkURL: item.artworkUrl600.flatMap(URL.init),
                feedURL: feedURL,
                source: .rss
            )
        }
    }

    // MARK: — Episodes (RSS parsing)

    func episodes(for show: PodcastShow) async throws -> [PodcastEpisode] {
        guard let feedURL = show.feedURL else { return [] }
        let (data, _) = try await URLSession.shared.data(from: feedURL)
        return RSSParser.parse(data: data, showId: show.id)
    }

    // MARK: — Playback

    func play(episode: PodcastEpisode) {
        guard let url = episode.audioURL else { return }

        player?.pause()
        playerObserver = nil

        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer
        nowPlaying = episode

        // Configure audio session for background playback
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)

        newPlayer.play()
        isPlaying = true

        // Observe playback status
        playerObserver = newPlayer.observe(\.timeControlStatus, options: [.new]) { [weak self] p, _ in
            Task { @MainActor in
                self?.isPlaying = p.timeControlStatus == .playing
            }
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func resume() {
        player?.play()
        isPlaying = true
    }

    func stop() {
        player?.pause()
        player = nil
        playerObserver = nil
        nowPlaying = nil
        isPlaying = false
    }
}

// MARK: — iTunes Search API response models

private struct iTunesSearchResult: Decodable {
    let results: [iTunesPodcast]
}

private struct iTunesPodcast: Decodable {
    let collectionId: Int
    let collectionName: String?
    let artistName: String?
    let feedUrl: String?
    let artworkUrl600: String?
}

// MARK: — Minimal RSS parser

private enum RSSParser {
    static func parse(data: Data, showId: String) -> [PodcastEpisode] {
        let parser = XMLParser(data: data)
        let delegate = RSSParserDelegate(showId: showId)
        parser.delegate = delegate
        parser.parse()
        return delegate.episodes
    }
}

private final class RSSParserDelegate: NSObject, XMLParserDelegate {
    let showId: String
    private(set) var episodes: [PodcastEpisode] = []

    private var currentTitle = ""
    private var currentDescription = ""
    private var currentEnclosureURL: URL?
    private var currentDuration: TimeInterval = 0
    private var currentPubDate: Date?
    private var insideItem = false
    private var currentElement = ""

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return f
    }()

    init(showId: String) {
        self.showId = showId
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            insideItem = true
            currentTitle = ""
            currentDescription = ""
            currentEnclosureURL = nil
            currentDuration = 0
            currentPubDate = nil
        }
        if insideItem && elementName == "enclosure" {
            if let urlStr = attributes["url"], attributes["type"]?.hasPrefix("audio") == true {
                currentEnclosureURL = URL(string: urlStr)
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard insideItem else { return }
        switch currentElement {
        case "title": currentTitle += string
        case "description", "summary": currentDescription += string
        case "pubDate": currentPubDate = Self.dateFormatter.date(from: string.trimmingCharacters(in: .whitespaces))
        case "duration": currentDuration = parseDuration(string.trimmingCharacters(in: .whitespaces))
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        if elementName == "item" && insideItem {
            let episode = PodcastEpisode(
                id: "\(showId)-\(episodes.count)",
                showId: showId,
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                description: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                audioURL: currentEnclosureURL,
                duration: currentDuration,
                publishedAt: currentPubDate,
                artworkURL: nil,
                source: .rss
            )
            episodes.append(episode)
            insideItem = false
        }
    }

    private func parseDuration(_ s: String) -> TimeInterval {
        let parts = s.split(separator: ":").compactMap { Int($0) }
        switch parts.count {
        case 1: return TimeInterval(parts[0])
        case 2: return TimeInterval(parts[0] * 60 + parts[1])
        case 3: return TimeInterval(parts[0] * 3600 + parts[1] * 60 + parts[2])
        default: return 0
        }
    }
}

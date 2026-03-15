import Foundation

struct PodcastShow: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let author: String
    let description: String
    let artworkURL: URL?
    let feedURL: URL?
    let source: PodcastSource
}

struct PodcastEpisode: Identifiable, Codable, Hashable {
    let id: String
    let showId: String
    let title: String
    let description: String
    let audioURL: URL?
    let duration: TimeInterval    // seconds, 0 if unknown
    let publishedAt: Date?
    let artworkURL: URL?
    let source: PodcastSource
}

enum PodcastSource: String, Codable, Hashable {
    case rss
    case spotify
}

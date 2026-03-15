import SwiftUI
import MediaPlayer

/// Now Playing controls on the watch.
/// Reads track info via MPNowPlayingInfoCenter (reflects iPhone's player on watchOS).
/// Sends play/pause/skip commands to the iPhone via WatchConnectivity.
struct AudioControlView: View {
    @Environment(WatchSessionManager.self) private var sessionManager

    @State private var title: String?
    @State private var artist: String?
    @State private var isPlaying: Bool = false
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 8) {
            if let title {
                Text(title)
                    .font(.caption2.bold())
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text(artist ?? "")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text("No audio playing")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 20) {
                Button {
                    sessionManager.sendMediaCommand(.skipPrevious)
                } label: {
                    Image(systemName: "backward.fill")
                }

                Button {
                    sessionManager.sendMediaCommand(.playPause)
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button {
                    sessionManager.sendMediaCommand(.skipNext)
                } label: {
                    Image(systemName: "forward.fill")
                }
            }
        }
        .padding(.horizontal)
        .onAppear {
            refreshNowPlaying()
            timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
                refreshNowPlaying()
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    // MARK: — Helpers

    private func refreshNowPlaying() {
        let info = MPNowPlayingInfoCenter.default().nowPlayingInfo
        title  = info?[MPMediaItemPropertyTitle] as? String
        artist = info?[MPMediaItemPropertyArtist] as? String
            ?? info?[MPMediaItemPropertyPodcastTitle] as? String
        let rate = info?[MPNowPlayingInfoPropertyPlaybackRate] as? Double ?? 0
        isPlaying = rate > 0
    }
}

import SwiftUI
import MediaPlayer

/// Now Playing controls on the watch — controls system audio player,
/// which works for both Apple Music and podcast AVPlayer playback.
struct AudioControlView: View {
    @State private var nowPlayingInfo: NowPlayingInfo?
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 8) {
            if let info = nowPlayingInfo {
                Text(info.title)
                    .font(.caption2.bold())
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text(info.artist)
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
                    MPRemoteCommandCenter.shared().previousTrackCommand.isEnabled = true
                    MPMusicPlayerController.systemMusicPlayer.skipToPreviousItem()
                } label: {
                    Image(systemName: "backward.fill")
                }

                Button {
                    let player = MPMusicPlayerController.systemMusicPlayer
                    if player.playbackState == .playing {
                        player.pause()
                    } else {
                        player.play()
                    }
                    refreshNowPlaying()
                } label: {
                    Image(systemName: nowPlayingInfo?.isPlaying == true ? "pause.fill" : "play.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button {
                    MPMusicPlayerController.systemMusicPlayer.skipToNextItem()
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

    private func refreshNowPlaying() {
        let player = MPMusicPlayerController.systemMusicPlayer
        guard let item = player.nowPlayingItem else {
            nowPlayingInfo = nil
            return
        }
        nowPlayingInfo = NowPlayingInfo(
            title: item.title ?? "Unknown",
            artist: item.artist ?? item.podcastTitle ?? "",
            isPlaying: player.playbackState == .playing
        )
    }
}

private struct NowPlayingInfo {
    let title: String
    let artist: String
    let isPlaying: Bool
}

# Walking Companion — Xcode Setup Guide

All Swift source files are already written. Follow these steps to create the Xcode project, wire up the targets, and deploy to TestFlight.

---

## Step 1 — Create the Xcode Project

1. Open Xcode → **File → New → Project**
2. Choose **iOS → App**
3. Set:
   - **Product Name:** `WalkingCompanion`
   - **Bundle Identifier:** `com.YOURNAME.walkingcompanion`
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** None (we use SwiftData manually)
4. Save the project **inside** `/Users/lhjtristram/AI Explorations/Walking Companion/`

---

## Step 2 — Add the Apple Watch Target

1. In Xcode: **File → New → Target**
2. Choose **watchOS → Watch App**
3. Set:
   - **Product Name:** `WalkingCompanionWatch`
   - **Bundle Identifier:** `com.YOURNAME.walkingcompanion.watchkitapp`
   - **Interface:** SwiftUI
4. When asked "Activate scheme?" → **Activate**

---

## Step 3 — Add Source Files to Each Target

### iPhone target (`WalkingCompanion`)
Delete Xcode's auto-generated `ContentView.swift` and `WalkingCompanionApp.swift`.
Then drag these folders into the `WalkingCompanion` group in the Project Navigator:
- `WalkingCompanion/Models/`
- `WalkingCompanion/Views/`
- `WalkingCompanion/Services/`
- `WalkingCompanion/WalkingCompanionApp.swift`
- `WalkingCompanion/WalkCoordinator.swift`
- `WalkingCompanion/Info.plist` → replace the generated one

### Watch target (`WalkingCompanionWatch`)
Delete Xcode's auto-generated watch files, then drag:
- `WalkingCompanionWatch/Views/`
- `WalkingCompanionWatch/Services/`
- `WalkingCompanionWatch/WalkingCompanionWatchApp.swift`
- `WalkingCompanionWatch/Info.plist` → replace the generated one

### Shared files (add to **both** targets)
Select both targets when dragging these files:
- `Shared/WalkMetrics.swift`
- `Shared/WatchMessage.swift`
- `Shared/PodcastModels.swift`
- `Shared/PodcastServiceProtocol.swift`

---

## Step 4 — Configure Capabilities

### iPhone target
In **Signing & Capabilities**, click **+** and add:
- **HealthKit** → check "Clinical Health Records" off, leave the rest
- **Background Modes** → check: Audio, Location updates, Workout processing
- **Apple Music** (adds NSAppleMusicUsageDescription automatically)

### Watch target
Add:
- **HealthKit**
- **Background Modes** → Workout processing

---

## Step 5 — Framework + Package Dependencies

In **Project → Package Dependencies**, add:

```
(none required for the prototype — all frameworks are Apple system frameworks)
```

When you add Spotify later:
- Add `https://github.com/spotify/ios-sdk` via Swift Package Manager
- Target: iPhone only
- Then update `SpotifyPodcastService.swift` with your Client ID

---

## Step 6 — Info.plist

The `WalkingCompanion/Info.plist` provided includes all required permission strings and background modes. Make sure Xcode is pointing to it (check **Build Settings → Info.plist File**).

---

## Step 7 — Sign & Deploy via TestFlight

1. Select your **Apple Developer Team** in Signing & Capabilities for both targets
2. Connect your iPhone via USB
3. **Product → Build** — fix any errors (usually missing team ID or bundle ID conflicts)
4. **Product → Archive**
5. In Organizer: **Distribute App → App Store Connect → Upload**
6. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com):
   - Create an app record for Walking Companion
   - Open **TestFlight** → Internal Testing → Add yourself as tester
7. Install TestFlight on your iPhone → accept invite → install the build

Your Apple Watch app installs automatically via the Watch app on iPhone.

---

## Step 8 — Spotify Setup (Optional)

1. Go to [developer.spotify.com/dashboard](https://developer.spotify.com/dashboard)
2. Create an app → note your **Client ID**
3. Add redirect URI: `walkingcompanion://spotify-callback`
4. Edit `SpotifyPodcastService.swift`:
   ```swift
   static let clientID = "YOUR_CLIENT_ID_HERE"
   ```
5. Add the SpotifyiOS SDK package in Xcode
6. Wire up the `SPTConfiguration` and `SPTAppRemote` calls (marked with TODO comments in the file)

---

## Verification Checklist

- [ ] Build succeeds for both iPhone and Watch targets
- [ ] App launches and shows permission prompts
- [ ] "Start Walk" button activates cadence streaming
- [ ] Cadence number updates on screen while walking
- [ ] Watch shows live cadence within ~2 seconds
- [ ] Start/stop works from Watch wrist
- [ ] Cadence alert fires (haptic + voice) after grace period
- [ ] Apple Music playlists load in Audio tab
- [ ] Podcast search returns results
- [ ] Walk saves to History after stopping
- [ ] Insights charts populate after 1–2 walks
- [ ] TestFlight build installs and runs without Xcode connected

---

## File Map

```
Walking Companion/
├── SETUP.md                          ← you are here
├── WalkingCompanion/                 # iPhone sources
│   ├── WalkingCompanionApp.swift     # @main, injects all environments
│   ├── WalkCoordinator.swift         # orchestrates services during a walk
│   ├── Models/
│   │   ├── WalkSession.swift         # SwiftData model
│   │   └── UserSettings.swift        # cadence target, alert preferences
│   ├── Views/
│   │   ├── ContentView.swift         # root tab bar
│   │   ├── HomeView.swift            # dashboard + quick start
│   │   ├── ActiveWalkView.swift      # live walk screen
│   │   ├── CoachingSettingsView.swift
│   │   ├── AudioView.swift           # music + podcast tabs
│   │   ├── HistoryView.swift
│   │   ├── SessionDetailView.swift
│   │   └── InsightsView.swift
│   ├── Services/
│   │   ├── CadenceService.swift      # CMPedometer streaming + alerts
│   │   ├── WorkoutService.swift      # HealthKit HKWorkoutSession
│   │   ├── LocationService.swift     # GPS distance + pace
│   │   ├── MusicService.swift        # MusicKit
│   │   ├── RSSPodcastService.swift   # iTunes Search + RSS + AVPlayer
│   │   ├── SpotifyPodcastService.swift  # Spotify SDK stub
│   │   ├── PodcastManager.swift      # aggregates podcast services
│   │   └── WatchConnector.swift      # WatchConnectivity (phone side)
│   └── Info.plist
├── WalkingCompanionWatch/            # Watch sources
│   ├── WalkingCompanionWatchApp.swift
│   ├── Views/
│   │   ├── MainWatchView.swift       # idle + active tabs
│   │   └── AudioControlView.swift   # now playing controls
│   ├── Services/
│   │   ├── WatchSessionManager.swift # WatchConnectivity (watch side)
│   │   └── WatchWorkoutService.swift # heart rate from wrist sensor
│   └── Info.plist
└── Shared/                           # added to both targets
    ├── WalkMetrics.swift
    ├── WatchMessage.swift
    ├── PodcastModels.swift
    └── PodcastServiceProtocol.swift
```

import Foundation
import SwiftUI

/// Progression system — the user holds the highest level they have ever unlocked.
enum CadenceLevel: Int, CaseIterable, Comparable {
    case beginnerWalker = 0
    case rhythmFinder   = 1
    case paceKeeper     = 2
    case briskWalker    = 3
    case powerWalker    = 4

    static func < (lhs: CadenceLevel, rhs: CadenceLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    // MARK: — Display

    var displayName: String {
        switch self {
        case .beginnerWalker: return "Beginner Walker"
        case .rhythmFinder:   return "Rhythm Finder"
        case .paceKeeper:     return "Pace Keeper"
        case .briskWalker:    return "Brisk Walker"
        case .powerWalker:    return "Power Walker"
        }
    }

    var requirement: String {
        switch self {
        case .beginnerWalker: return "Complete 3 walks"
        case .rhythmFinder:   return "Maintain cadence for 10 minutes in a walk"
        case .paceKeeper:     return "Stay at cadence for 70% of a walk"
        case .briskWalker:    return "Average cadence > 115 spm in a walk"
        case .powerWalker:    return "Average cadence > 125 spm in a walk"
        }
    }

    var icon: String {
        switch self {
        case .beginnerWalker: return "figure.walk"
        case .rhythmFinder:   return "metronome"
        case .paceKeeper:     return "checkmark.seal"
        case .briskWalker:    return "hare"
        case .powerWalker:    return "bolt.fill"
        }
    }

    var color: Color {
        switch self {
        case .beginnerWalker: return .gray
        case .rhythmFinder:   return .blue
        case .paceKeeper:     return .green
        case .briskWalker:    return .orange
        case .powerWalker:    return .purple
        }
    }

    // MARK: — Progression

    var next: CadenceLevel? {
        CadenceLevel(rawValue: rawValue + 1)
    }

    // MARK: — Unlock evaluation

    /// Returns the highest level the user has unlocked across all their walks.
    static func earned(from sessions: [WalkSession]) -> CadenceLevel {
        var highest: CadenceLevel = .beginnerWalker

        for level in CadenceLevel.allCases {
            if isUnlocked(level, from: sessions) {
                highest = level
            }
        }
        return highest
    }

    /// 0.0–1.0 progress toward the *next* level (used for progress bar).
    func progressToNext(from sessions: [WalkSession]) -> Double {
        guard let nextLevel = next else { return 1.0 }   // at max level

        switch nextLevel {
        case .beginnerWalker:
            return 0

        case .rhythmFinder:
            // Progress: walks completed / 3
            let count = sessions.count
            return min(1.0, Double(count) / 3.0)

        case .paceKeeper:
            // Progress: best minutesAtCadence / 10
            let best = sessions.map(\.minutesAtCadence).max() ?? 0
            return min(1.0, best / 10.0)

        case .briskWalker:
            // Progress: best percentAtCadence / 70
            let best = sessions.map(\.percentAtCadence).max() ?? 0
            return min(1.0, best / 70.0)

        case .powerWalker:
            // Progress: best avg cadence above 115 toward 125
            let best = Double(sessions.map(\.averageCadence).max() ?? 0)
            let clamped = max(0.0, best - 115.0)
            return min(1.0, clamped / 10.0)    // 115→125 range
        }
    }

    // MARK: — Private helpers

    private static func isUnlocked(_ level: CadenceLevel, from sessions: [WalkSession]) -> Bool {
        switch level {
        case .beginnerWalker:
            return sessions.count >= 3

        case .rhythmFinder:
            return sessions.contains { $0.minutesAtCadence >= 10 }

        case .paceKeeper:
            return sessions.contains { $0.percentAtCadence >= 70 }

        case .briskWalker:
            return sessions.contains { $0.averageCadence > 115 }

        case .powerWalker:
            return sessions.contains { $0.averageCadence > 125 }
        }
    }
}

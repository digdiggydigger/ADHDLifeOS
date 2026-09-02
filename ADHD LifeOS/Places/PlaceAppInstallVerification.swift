//
//  PlaceAppInstallVerification.swift
//  ADHD LifeOS
//
//  Config-time install verification (F-AppDirectory-3-Verify). NOT 17-gated: pure logic plus
//  a one-method UIKit adapter, all compiling at the 16.0 floor.
//
//  The iOS facts this file is shaped around: `canOpenURL` answers honestly ONLY for schemes
//  declared in `LSApplicationQueriesSchemes`; for an undeclared scheme it returns `false`
//  indistinguishably from "not installed"; the key caps at 50 schemes and is COMPILE-TIME
//  only, so remote directory entries can never gain a verification slot. Hence three honest
//  states, decided BEFORE the call — and for an undeclared scheme the call is never made.
//

import Foundation
import UIKit

/// The curated subset of the bundled directory with a verification slot — the top of the
/// rank order (the apps E will actually pick) plus the everyday UK-life four. MUST stay in
/// lockstep with the `LSApplicationQueriesSchemes` array in `Info.plist`: the parity test
/// reads the built product and set-compares, so drift is a red test, not a silent lie.
/// Deliberately capped at 45 — headroom under iOS's 50 so a future need doesn't evict.
enum PlaceQueryableSchemes {
    static let declared: [String] = [
        // 95–90
        "comgooglemaps", "youtube", "whatsapp", "spotify", "maps", "instagram",
        // 85–80
        "music", "googlegmail", "tiktok", "nflx", "fb", "twitter",
        // 75
        "message", "photos-redirect", "chatgpt", "uber", "com.amazon.mobile.shopping",
        // 70
        "calshow", "mobilenotes", "googlechrome", "discord", "reddit", "fb-messenger", "claude",
        // 65
        "googledrive", "slack", "snapchat", "tg", "notion",
        // 60
        "itms-apps", "facetime", "podcasts", "x-apple-reminderkit", "waze", "linkedin",
        "msteams", "zoomus", "disneyplus", "twitch", "ms-outlook", "citymapper",
        // The everyday four from the 55 tier — gym, food, food, bank.
        "strava", "deliveroo", "ubereats", "monzo"
    ]

    static let declaredSet = Set(declared)
}

/// The three honest states. There is deliberately no way to say "not installed" without a
/// declared scheme having actually been asked.
enum PlaceAppInstallVerdict: Equatable {
    case looksInstalled
    case doesNotLookInstalled
    case cannotCheck

    /// Decided BEFORE `canOpen`: no scheme, an undeclared scheme, or one that can't form a
    /// URL is `.cannotCheck` and `canOpen` is never consulted — calling it would launder
    /// "no queries slot" into "not installed", which is a lie the tripwire test forbids.
    static func verdict(
        scheme: String?,
        declared: Set<String> = PlaceQueryableSchemes.declaredSet,
        canOpen: (URL) -> Bool
    ) -> PlaceAppInstallVerdict {
        guard let scheme, declared.contains(scheme),
              let url = URL(string: "\(scheme)://") else { return .cannotCheck }
        return canOpen(url) ? .looksInstalled : .doesNotLookInstalled
    }
}

/// Pinned copy — the "doesn't look installed" line reassures rather than blocks, and the
/// "can't check" line never claims knowledge it doesn't have.
enum PlaceAppInstallCopy {
    static func line(for verdict: PlaceAppInstallVerdict) -> String {
        switch verdict {
        case .looksInstalled:
            return "Installed on this iPhone."
        case .doesNotLookInstalled:
            return "Doesn't look installed. Saving is fine — the tap will say so honestly "
                + "if it can't open."
        case .cannotCheck:
            return "Can't check whether this app is installed. If it isn't, the notification "
                + "tap will tell you."
        }
    }
}

/// The one-method seam over `UIApplication.canOpenURL`, so views take a closure and tests
/// never touch UIKit.
protocol SchemeInstallChecking {
    @MainActor func canOpen(_ url: URL) -> Bool
}

struct UIApplicationSchemeInstallChecker: SchemeInstallChecking {
    @MainActor func canOpen(_ url: URL) -> Bool {
        UIApplication.shared.canOpenURL(url)
    }
}

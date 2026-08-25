//
//  AboutInfo.swift
//  ADHD LifeOS
//

import Foundation

/// The About row's numbers, read honestly from the bundle (E's 2026-08-25 Settings audit — the
/// old placeholder promised "version, environment, and last refresh"; version and build are the
/// two that truthfully exist, per E's call, so they are what ships).
struct AboutInfo: Equatable {
    let version: String
    let build: String

    /// "1.4 (87)" — the string a bug report wants.
    var formatted: String { "\(version) (\(build))" }

    static func read(fromInfo info: [String: Any]) -> AboutInfo {
        AboutInfo(
            version: info["CFBundleShortVersionString"] as? String ?? "—",
            build: info["CFBundleVersion"] as? String ?? "—"
        )
    }

    static var current: AboutInfo {
        read(fromInfo: Bundle.main.infoDictionary ?? [:])
    }
}

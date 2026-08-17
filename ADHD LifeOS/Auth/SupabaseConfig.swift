//
//  SupabaseConfig.swift
//  ADHD LifeOS
//

import Foundation

/// Reads the Supabase project URL and anon key from Info.plist, populated at build time
/// from `Supabase.xcconfig`. Both values are the public client credentials (same ones the
/// web app ships in its client-side bundle) — safe to keep out of source control only as a
/// matter of convention, not because they're secret; Row-Level Security is what protects data.
enum SupabaseConfig {
    static var projectURL: URL {
        guard
            let string = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            !string.isEmpty,
            let url = URL(string: string)
        else {
            fatalError("SUPABASE_URL is missing from Info.plist — set it in Supabase.xcconfig")
        }
        return url
    }

    static var anonKey: String {
        guard
            let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
            !key.isEmpty
        else {
            fatalError("SUPABASE_ANON_KEY is missing from Info.plist — set it in Supabase.xcconfig")
        }
        return key
    }

    static var authURL: URL {
        projectURL.appendingPathComponent("auth/v1")
    }

    static var authCallbackURL: URL {
        URL(string: "adhdlifeos://auth-callback")!
    }
}

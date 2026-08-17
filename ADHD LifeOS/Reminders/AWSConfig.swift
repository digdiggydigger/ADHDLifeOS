//
//  AWSConfig.swift
//  ADHD LifeOS
//

import Foundation

/// Base URL for the Stage A AWS Reminders endpoint (`poke-ios-bridge` behind API Gateway).
/// Unlike `SupabaseConfig`, this is **not** read from an xcconfig/Info.plist secret — the route
/// carries no credential and has no authorizer attached (by design, see
/// `docs/MIGRATION-SUPABASE-TO-AWS.md`), so the URL itself is not sensitive. This moves to
/// xcconfig in Stage B once Cognito lands and the route needs environment-specific values.
enum AWSConfig {
    static var remindersBaseURL: URL {
        URL(string: "https://qxbwx2qjq7.execute-api.us-east-1.amazonaws.com/prod")!
    }
}

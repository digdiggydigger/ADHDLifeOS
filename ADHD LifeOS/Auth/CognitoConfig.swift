//
//  CognitoConfig.swift
//  ADHD LifeOS
//

import Foundation

/// Cognito resources for Stage C.1's `AWSAuthClientAdapter`. The pool ID and app client ID are
/// public identifiers on a no-secret native app client (same safety class as `AWSConfig`'s
/// existing Reminders base URL) — safe to commit, per `docs/STAGE-B-COGNITO-DYNAMODB-LAMBDA.md`.
enum CognitoConfig {
    static let userPoolID = "us-east-1_fOmtVlMih"
    static let appClientID = "57v25l4t62spds2qkvkhtbq0ae"
    static let region = "us-east-1"

    static var identityProviderURL: URL {
        URL(string: "https://cognito-idp.\(region).amazonaws.com/")!
    }
}

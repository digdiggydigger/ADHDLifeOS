//
//  LifeOSAPIConfig.swift
//  ADHD LifeOS
//

import Foundation

/// Base URL for `life-os-api-gw`, the Stage C AWS backend for tasks/life-areas/etc. Public
/// identifier on a JWT-authorized route, same "safe to commit" precedent as `CognitoConfig`.
enum LifeOSAPIConfig {
    static var baseURL: URL {
        URL(string: "https://2pzqn8yih5.execute-api.us-east-1.amazonaws.com/prod")!
    }
}

/// Every AWS Lambda-generated id (`create_task`/`create_tag`, both via Python's `uuid.uuid4()`)
/// stringifies lowercase, and DynamoDB does exact-match key lookups on that literal string.
/// `UUID.uuidString` always stringifies UPPERCASE regardless of a value's origin, so any UUID
/// embedded back into a URL path or JSON body bound for a case-sensitive DynamoDB lookup must go
/// through this property instead — see the FIX block in the Claude Code task list for the bug
/// this closes.
extension UUID {
    var lowercaseUUIDString: String {
        uuidString.lowercased()
    }
}

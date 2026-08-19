//
//  UUIDLowercaseString.swift
//  ADHD LifeOS
//

import Foundation

/// `UUID.uuidString` always stringifies UPPERCASE. Callers that need a canonical lowercase form
/// for case-sensitive string comparisons (originally AWS Lambda `uuid.uuid4()` ids; today the
/// reorder payload and editor presentation helpers still normalize through it) use this property.
/// Lived in `LifeOSAPIConfig.swift` until the Firebase cutover deleted the AWS config around it.
/// Note the Firebase layer itself stores document IDs as plain `uuidString` (uppercase),
/// consistently on both write and read — do not mix the two forms for Firestore paths.
extension UUID {
    var lowercaseUUIDString: String {
        uuidString.lowercased()
    }
}

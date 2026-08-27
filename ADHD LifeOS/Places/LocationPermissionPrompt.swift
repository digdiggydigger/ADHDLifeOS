//
//  LocationPermissionPrompt.swift
//  ADHD LifeOS
//

import Foundation

/// What a location-permission banner should say, and what its button should do.
///
/// Pure, so the copy and the escalation order are testable — and they are the parts most worth
/// pinning. Ask for Always cold and iOS shows a weaker prompt that users decline markedly more
/// often, so the supported path is When In Use first, then escalate once places exist and the
/// feature means something. Re-prompting a denied user does nothing at all: iOS will not show the
/// sheet a second time, so the only honest button there is one that opens Settings.
struct LocationPermissionPrompt: Equatable {
    enum Action: Equatable {
        case request(LocationAuthorizationRequest)
        case openSettings
        /// Nothing the user can do from here — restricted by parental controls or an MDM profile.
        case none
    }

    let message: String
    let buttonTitle: String?
    let action: Action
    /// Drives the tone: an invitation looks quiet, a blocked feature looks like a problem.
    let isWarning: Bool

    /// `nil` when the current grant already covers what this screen needs — there is nothing to say.
    static func prompt(
        for state: LocationAuthorizationState,
        wantsTriggering: Bool
    ) -> LocationPermissionPrompt? {
        switch state {
        case .always:
            return nil

        case .notDetermined:
            return LocationPermissionPrompt(
                message: "Momentum can remember where a capture or sprint happened. "
                    + "It only ever checks while you're using the app.",
                buttonTitle: "Allow location",
                action: .request(.whenInUse),
                isWarning: false
            )

        case .whenInUse:
            guard wantsTriggering else { return nil }
            return LocationPermissionPrompt(
                message: "Arrival nudges need Always access, so Momentum can notice you've "
                    + "reached a place while the app is closed.",
                buttonTitle: "Allow Always",
                action: .request(.always),
                isWarning: false
            )

        case .denied:
            return LocationPermissionPrompt(
                message: "Location is turned off for Momentum, so nothing records where it "
                    + "happened. You can turn it back on in Settings.",
                buttonTitle: "Open Settings",
                action: .openSettings,
                isWarning: true
            )

        case .restricted:
            return LocationPermissionPrompt(
                message: "Location isn't available on this device — it's restricted by a profile "
                    + "or parental controls.",
                buttonTitle: nil,
                action: .none,
                isWarning: true
            )
        }
    }
}

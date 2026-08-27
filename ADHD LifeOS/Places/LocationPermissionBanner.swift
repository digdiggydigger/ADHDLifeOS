//
//  LocationPermissionBanner.swift
//  ADHD LifeOS
//

import SwiftUI
import UIKit

/// The ask. Explains what location is for in this app, then raises the system prompt — or sends
/// the user to Settings when iOS will no longer show one.
///
/// It watches `authorizationChanges` rather than polling: the delegate callback is the only signal
/// that the user answered the system sheet, and without it the banner would sit there still asking
/// for permission that had just been granted.
@available(iOS 17.0, *)
struct LocationPermissionBanner: View {
    /// Whether this screen needs the Always grant (arrival triggering) or just When In Use.
    let wantsTriggering: Bool

    @ObservedObject private var provider = CoreLocationFixProvider.shared

    private var prompt: LocationPermissionPrompt? {
        // Reading `authorizationChanges` here is what re-evaluates this when the answer lands.
        _ = provider.authorizationChanges
        return LocationPermissionPrompt.prompt(
            for: provider.authorizationState,
            wantsTriggering: wantsTriggering
        )
    }

    var body: some View {
        if let prompt {
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text(prompt.message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: prompt.isWarning ? "exclamationmark.triangle.fill" : "location")
                        .foregroundStyle(prompt.isWarning ? Color("StateWarn") : Color.accentColor)
                }

                if let buttonTitle = prompt.buttonTitle {
                    Button(buttonTitle) { act(on: prompt.action) }
                        .buttonStyle(MomentumBorderedButtonStyle(minHeight: 44))
                        .accessibilityIdentifier("locationPermissionButton")
                }
            }
            .padding(.vertical, 8)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("locationPermissionBanner")
        }
    }

    private func act(on action: LocationPermissionPrompt.Action) {
        switch action {
        case .request(let request):
            Haptics.play(.light)
            provider.request(request)
        case .openSettings:
            Haptics.play(.light)
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        case .none:
            break
        }
    }
}

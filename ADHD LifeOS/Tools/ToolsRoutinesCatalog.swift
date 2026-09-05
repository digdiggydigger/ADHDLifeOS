//
//  ToolsRoutinesCatalog.swift
//  ADHD LifeOS
//
//  The Routines section of the Tools page, as a pure list (F-Routines-B-ToolsSection, E's
//  2026-09-05 call: "the routines section deserves its own Routines section on the Tool list").
//
//  **This type decides nothing.** A routine still has no independent existence — it IS a place's
//  actions for one direction — so membership, the ≥ threshold rule and the step count are all
//  `PlaceRoutinePlan`'s answers, asked here rather than re-derived. Re-implementing any of them
//  would put a second truth about one routine on a second screen, which is the defect this repo
//  produces most (`CaptureInboxTriageCountsTests` is the last one that shipped).
//
//  Kept out of the view body for the reason every presentation type here is: view bodies are
//  ~0% covered by design, so a rule left inside one is a rule nothing checks. `ToolsCatalog`
//  and `PlaceAppPickerPresentation` are the house pattern.
//

import Foundation

enum ToolsRoutinesCatalog {

    /// The section's own words. The threshold is INTERPOLATED, never spelled out, because
    /// `RoutineDefaults.stepThreshold` is a knob E owns — copy saying "two" beside a constant
    /// reading 3 is a lie the compiler cannot catch.
    static let sectionTitle = "Routines"

    static var sectionCaption: String {
        "What a place runs when you arrive or leave — \(thresholdPhrase) steps that need a tap."
    }

    /// `PlacesListView`'s own fallback, matched deliberately: the same place must not wear a
    /// different glyph on two screens.
    static let glyphFallback = "📍"

    private static var thresholdPhrase: String { "\(RoutineDefaults.stepThreshold) or more" }

    // MARK: - Nothing to show, and WHY there is nothing

    /// Two different problems with two different next actions, so they never share a sentence.
    /// A brand-new account is in the first of these, and first-run is the state nothing in this
    /// repo tests — every journey seeds what it is about before launching.
    enum EmptyReason: Equatable, CaseIterable {
        /// No places at all. The next action is to make one.
        case noPlaces
        /// Places exist; none has enough tap-steps. The next action is to add a step.
        case noQualifyingPlaces

        var headline: String { "No routines yet" }

        var body: String {
            switch self {
            case .noPlaces:
                return "Add a place first. Give it \(thresholdPhrase) steps that need a tap —"
                    + " opening an app, texting someone — and arriving there will offer them as"
                    + " one routine instead of separate notifications."
            case .noQualifyingPlaces:
                return "A place becomes a routine when \(thresholdPhrase) of its steps need a"
                    + " tap. Yours have fewer than that, so they still arrive as a single"
                    + " notification you tap once."
            }
        }

        /// Both doors lead to Places; the words differ because the job does.
        var actionTitle: String {
            switch self {
            case .noPlaces: return "Set up a place"
            case .noQualifyingPlaces: return "Open Places"
            }
        }

        var accessibilityIdentifier: String {
            switch self {
            case .noPlaces: return "toolsRoutinesEmpty.noPlaces"
            case .noQualifyingPlaces: return "toolsRoutinesEmpty.noQualifyingPlaces"
            }
        }
    }

    // MARK: - One row per place + direction

    /// One routine, as the section draws it. Deliberately does NOT carry its `Place`: the view
    /// already holds the loaded list and looks the place up by id when it opens the editor, so
    /// this stays a small value the tests can compare whole.
    struct Row: Identifiable, Equatable {
        let placeId: UUID
        let kind: PlaceTriggerEvent.Kind
        let glyph: String
        let title: String
        let subtitle: String

        var id: String { "\(placeId.uuidString)-\(kind.rawValue)" }

        /// Per-ROW and never on a container: an identifier on a container is inherited by its
        /// children and overrides their own — the trap that renamed the routine card's Continue
        /// button out from under itself.
        var accessibilityIdentifier: String { "toolsRoutineRow-\(id)" }
    }

    enum Content: Equatable {
        case rows([Row])
        case empty(EmptyReason)
    }

    /// What the section should draw for this place list.
    static func content(from places: [Place]) -> Content {
        let rows = rows(from: places)
        guard rows.isEmpty else { return .rows(rows) }
        return .empty(places.isEmpty ? .noPlaces : .noQualifyingPlaces)
    }

    /// Every routine these places would actually offer, in the Places list's own order.
    ///
    /// `PlacesService.sorted` is REUSED rather than copied: two screens listing the same places
    /// in different orders is a small lie that costs a real re-scan. Arrival leads within a
    /// place — it is the crossing you meet first in the day and first in the editor.
    static func rows(from places: [Place]) -> [Row] {
        PlacesService.sorted(places).flatMap { place in
            [PlaceTriggerEvent.Kind.arrival, .departure].compactMap { row(for: place, kind: $0) }
        }
    }

    private static func row(for place: Place, kind: PlaceTriggerEvent.Kind) -> Row? {
        let plan = PlaceRoutinePlan.make(place.actions, for: kind)
        // The ≥ threshold decision, asked of the type that owns it. A literal comparison here
        // would be a second spelling of E's settled call, free to drift from the notification's.
        guard plan.qualifiesAsRoutine else { return nil }
        return Row(
            placeId: place.id,
            kind: kind,
            glyph: place.emoji ?? glyphFallback,
            title: title(for: kind),
            // TAP-steps, the same count the banner and the Today card use. An auto step runs
            // itself and is never "ready", so it is named nowhere in this number.
            subtitle: "\(place.name) · \(stepsPhrase(plan.tapSteps.count))"
        )
    }

    /// Second person, matching the notification ("You're at Home" / "Leaving Home") rather than
    /// the editor's field labels — a row here is a moment, not a form field.
    static func title(for kind: PlaceTriggerEvent.Kind) -> String {
        switch kind {
        case .arrival: return "When you arrive"
        case .departure: return "When you leave"
        }
    }

    /// `qualifiesAsRoutine` makes "1 step" unreachable today, but the count is rendered from a
    /// variable and the threshold is E's knob — this costs one line and takes "1 steps" out of
    /// the set of things a later retune can ship.
    static func stepsPhrase(_ count: Int) -> String {
        count == 1 ? "1 step" : "\(count) steps"
    }
}

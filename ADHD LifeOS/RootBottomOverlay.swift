//
//  RootBottomOverlay.swift
//  ADHD LifeOS
//
//  Split out of `RootView` in F-Tools-1-Bar. The reason is prosaic — RootView was at 397 of
//  SwiftLint's 400-line ceiling before a sixth tab and a custom bar were added to it — but this
//  stack was the right thing to lift out: it is the app's one persistent bottom furniture (the
//  capture disc, an unacknowledged sprint summary, the running timer), it has nothing to do with
//  tabs, and it reads better named than inlined.
//

import SwiftUI

/// Everything that floats above the tab bar on every tab.
///
/// The pieces share one container so an active sprint PUSHES the disc up rather than letting
/// the timer bar occlude the disc's controls (E, 2026-08-19), and the whole thing is trailing-
/// pinned at full width because a `.bottom` overlay would otherwise centre it mid-screen once the
/// timer bar was gone (E's position review, 2026-08-25).
///
/// **Two arrangements since F-LandscapeFabOverlap (2026-09-17).** In regular height the container
/// is that stack — the disc row above the cards, exactly as reviewed. In COMPACT height (the
/// landscape iPhone) with anything up, the cards take the column BESIDE the disc row instead:
/// 372pt of landscape cannot hold the 100pt lift, a 186pt card, the gap and the disc in one
/// column without the disc's top landing at y 18, inside the header's gear well — which is where
/// E photographed it, on the Settings gear. `RootBottomOverlayLayout` holds the rule and the
/// geometry; this view only asks it.
struct RootBottomOverlay: View {
    @Binding var isFabOpen: Bool
    /// The disc's sticky scrolled-down state (F-PillStay). Passed in rather than observed here:
    /// RootView owns the model that the window-level pan observer feeds.
    let showsPill: Bool
    @ObservedObject var focusService: FocusSessionService
    /// What the current tab searches, or `.none`. Driven by `selectedTab` in RootView rather than
    /// by each screen registering itself: `AppTabContent` keeps every visited tab alive, so
    /// `.onAppear`/`.onDisappear` fire once and then effectively never again.
    var searchScope: AppSearchScope = .none
    /// Opens the full-screen surface. The screen presents it; this only asks.
    var onOpenSearch: () -> Void = {}
    /// The Journal's pencil disc (`F-JournalPencilDisc`): whether it is up, decided in RootView by
    /// `JournalComposeDoor.isShown`, and the request it sends. Same shape as the search row's pair
    /// — this view never learns which tab is selected.
    var showsJournalCompose = false
    var onWriteEntry: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Compact height is the landscape iPhone — the same reading `CaptureFanOverlay` and
    /// `LoginView` use. An iPad is regular in both orientations and keeps the stack.
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    /// The celebration centre, or the inert default outside the app (previews, snapshots).
    @Environment(\.celebrate) private var celebrate

    /// E's 2026-08-31 margin pass lifted the stack a further 8pt off the tab bar (52 → 60),
    /// matching the trailing margin's 16 → 24 so `CaptureDiscMetrics.clearance` stays one number
    /// for both axes.
    ///
    /// **The claim that used to sit here — that `.bottom` alignment already means the top of the
    /// bar, so the bar's height needs no correction — was WRONG, and it shipped.** This is an
    /// `.overlay(alignment: .bottom)`, and its `.bottom` resolves to the screen's original safe
    /// area even though the bar is applied as a `safeAreaInset` above it. Measured on E's device:
    /// disc frame bottom 758pt against a bar top of 751pt, a 7pt OVERLAP — the disc was sitting on
    /// the bar, not above it. E reported it while approving the search row: *"make sure that you
    /// have added spacing between the top of the menu/nav tab bar and the collapsed pill."*
    ///
    /// So the lift is the gap PLUS the bar, derived in `AppSearchRowMetrics.bottomFurnitureLift`.
    ///
    /// Spelled in `AppSearchRowMetrics` since F-Search-1-Row so a test can hold it: E re-confirmed
    /// this gap by name when approving the search row.
    private static var bottomPadding: CGFloat { AppSearchRowMetrics.bottomFurnitureLift }

    /// Whether anything but the disc row is up — the away card, a waiting Confirm, a running
    /// sprint. Each of the three sits behind its own condition below, and `FocusTimerBar` draws
    /// nothing without a session, so this is the column's emptiness spelled once.
    private var hasCards: Bool {
        focusService.offlineCompletionSummary != nil
            || !focusService.unconfirmedCompletions.isEmpty
            || focusService.isActive
    }

    private var arrangement: RootBottomOverlayLayout.Arrangement {
        RootBottomOverlayLayout.arrangement(
            isCompactHeight: verticalSizeClass == .compact, hasCards: hasCards
        )
    }

    /// The cards' visibility under the capture fan — see `RootBottomOverlayLayout.cardsPresence`.
    private var fanPresence: RootBottomOverlayLayout.CardsPresence {
        RootBottomOverlayLayout.cardsPresence(fanIsOpen: isFabOpen)
    }

    /// The curve everything that steps aside for the fan fades on — the cards and, since
    /// `F-JournalPencilDisc`, the Journal's pencil disc. Spelled once so the two fade together.
    /// Reduce Motion gets the same fade on a plain ease (§5's one exception), never a cut.
    private var fanFade: Animation {
        reduceMotion ? .default : .spring(response: 0.35, dampingFraction: 0.8)
    }

    var body: some View {
        // ONE container whose arrangement is a property, never a `switch` between a `VStack` and
        // an `HStack`: two container types would give the timer bar two identities, and its
        // detail sheet — `@State` on that view — would be dismissed by a rotation.
        // F-FanXAtRest (E's shape B, 2026-09-17): while the fan is open the Layout drops the disc
        // row — the ×, and on Tasks the search row beside it — to its resting corner, so it can
        // never sit on a tile. See `RootBottomOverlayLayout.frames`.
        RootBottomOverlayArrangement(arrangement: arrangement, fanIsOpen: isFabOpen) {
            discRow
                // In FRONT of the cards: the × drops into the space they still hold, and they are
                // subview 1, drawn over it. Without this it passes behind a half-faded card — and
                // under Reduce Motion it jumps there at once and sits behind the whole fade.
                .zIndex(1)
            cards
                // F-FanCardsFade (E's call, 2026-09-17): while the fan is open the cards fade out
                // and stop taking touches, but KEEP their layout — an opacity, never an `if` — so
                // the timer bar keeps its detail sheet and Stop confirmation (both `@State` on
                // it). Reduce Motion gets the same fade on a plain ease (§5's one exception).
                .opacity(fanPresence.opacity)
                .allowsHitTesting(fanPresence.acceptsTouches)
                .animation(fanFade, value: isFabOpen)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.bottom, Self.bottomPadding)
        // F-FanXAtRest: the × travels on the fan's own spring WHICHEVER way the fan opens or
        // closes. The disc's button toggles inside a `withAnimation`, but RootView's scrim and
        // tile pick set `isFabOpen` bare, and without this the × would snap 68–194pt back up on a
        // scrim dismissal. `nil` under Reduce Motion is §7.2's continuous re-layout, the same
        // reading as the push below when a sprint starts; the cards keep their own fade above.
        .animation(
            reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8),
            value: isFabOpen
        )
        .animation(
            reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8),
            value: focusService.isActive
        )
        // F-TabDepth-2: the row leaves and returns on the same spring — a pushed task detail
        // sees it slide away rather than pop beside the disc. Keyed on the scope, so the timer
        // bar's own trigger above is untouched.
        .animation(
            reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8),
            value: searchScope
        )
        // F-FocusCard-2: a completion is the one moment BOTH cards move — the running card
        // leaves as the confirmation card arrives, and again in reverse on Confirm. `isActive`
        // above covers only the first half, so without this the new card simply pops in.
        .animation(
            reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8),
            value: focusService.unconfirmedCompletions.count
        )
        // F-FocusCard-4: the success feel for a sprint that ran its countdown out. **On this
        // view and not on the stack**, because the stack is inserted by the `if` below in the
        // same update that bumps the count, and a listener arriving with the value already
        // changed observes no change — the first card after an empty stack would be silent.
        // Keyed on `confirmableCompletionCount`, never `completedSprintCount` (bumped by manual
        // stops, which raise no card) nor the stack's depth (falls on Confirm, so it would buzz
        // on dismissal). `.haptic` is the `#available`-split helper — `.sensoryFeedback` itself
        // is iOS 17+ against the 16.0 floor.
        .haptic(.success, trigger: focusService.confirmableCompletionCount)
        // F-ConfirmCelebration-1 (E's decision 3): the success feel on EVERY Confirm, keyed on the
        // Confirm ordinal, which only a Confirm of a waiting card advances. Here beside the
        // completion haptic for the same reason — the stack leaves with the last card, so a
        // listener on it would be gone before the Confirm that empties it could buzz.
        .haptic(.success, trigger: focusService.confirmationCount)
        // F-CTACelebrations-3: the bridge from the Confirm stamp to the celebration centre,
        // beside the haptic and for the same reason — this view is always mounted, and the
        // card stack that a Confirm empties is gone before the Confirm lands.
        //
        // **It asks; it never decides.** The Celebrations switch, the cooldown and the queue
        // all live in the centre, which is why E's #3 can keep the haptic above while
        // silencing the celebration: nothing on this line knows the switch exists.
        .onChange(of: focusService.latestConfirmation) { confirmation in
            guard let confirmation else { return }
            celebrate.request(.confirm(clearedStack: confirmation.clearedStack), at: nil)
        }
    }

    // MARK: - The two pieces

    /// E's layout (2026-09-03): the search field fills the leading width and the capture disc
    /// sits at the end of the SAME row, centres aligned. One `HStack` lays both out, so the
    /// alignment is by construction rather than two views agreeing on a number.
    ///
    /// The centres cannot drift: the disc's outer frame stays `discDiameter` square in BOTH
    /// states — only the visual capsule shrinks to the pill — so the row's height is the disc's,
    /// and the shorter field centres inside it.
    ///
    /// The same view in both arrangements. Stacked it is offered the whole width and the field
    /// fills the leading side; beside the cards it takes its own width, so on Today it is the
    /// disc and its margins and the cards get the rest.
    private var discRow: some View {
        HStack(spacing: AppSearchRowMetrics.rowSpacing) {
            // `F-C1-UndoCapsule` (E's round 2b, shape A): the row's THIRD occupant, and the one
            // that displaces the other two. E: *"It sits exactly where the search row is, left of
            // the + disc. Nothing moves and nothing stacks... On Tasks it stands in for the search
            // row until the next action"*, and E's Step 0 answer 4 says the same for the Journal's
            // pencil disc. So it wraps the whole leading band rather than joining it as a fourth
            // thing: the + disc never moves either way, and the outgoing occupant leaves on the
            // same fade the capsule arrives on.
            UndoCapsuleSlot {
                leadingBand
            }
            Button {
                withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
                    isFabOpen.toggle()
                }
            } label: {
                CaptureDiscLabel(isFabOpen: isFabOpen, showsPill: showsPill)
            }
            .accessibilityLabel(isFabOpen ? "Close capture fan" : "Capture something")
            .accessibilityIdentifier("quickCaptureButton")
        }
        // The disc's own trailing margin, unchanged — E's number, settled over four device
        // passes. The field takes the page's 16pt margin on the leading side.
        .padding(.leading, 16)
        .padding(.trailing, CaptureDiscMetrics.edgeMargin)
    }

    /// What the leading band holds when no undo is pending: the search row on the tabs that have
    /// one, the Journal's pencil disc on the Journal, nothing anywhere else.
    @ViewBuilder
    private var leadingBand: some View {
        if let placeholder = searchScope.placeholder {
            AppSearchRow(placeholder: placeholder, action: onOpenSearch)
        }
        // F-JournalPencilDisc (E, 2026-09-18): *"move the filled pencil icon disc down to the
        // left-hand side of the FAB Icon. make the filled pencil disc inline with the FAB
        // icon"*. In this `HStack`, so the shared centre line is by construction and the +
        // never moves: the row grows leftward by the disc and the 16pt gap.
        //
        // While the fan is open it steps aside WITH the cards — invisible and untouchable, by
        // the same rule (decision 6; `F-FanCardsFade` is the precedent) — and it arrives and
        // leaves on a fade whose Reduce Motion path is a plain ease, never a cut (§7.2). The
        // arrival's curve rides on the TRANSITION, so this row's other animations (the search
        // row's, keyed on the scope) are untouched when both change on one tab switch.
        if showsJournalCompose {
            JournalComposeDisc(showsPill: showsPill, action: onWriteEntry)
                .opacity(fanPresence.opacity)
                .allowsHitTesting(fanPresence.acceptsTouches)
                // …and out of VoiceOver's reach with it: hit-testing stops a finger, not
                // VoiceOver's activate, which could otherwise open the composer under the scrim.
                .accessibilityHidden(!fanPresence.acceptsTouches)
                .animation(fanFade, value: isFabOpen)
                .transition(.opacity.animation(JournalComposeDoor.appearAnimation(reduceMotion: reduceMotion)))
        }
    }

    /// The column under the disc row (regular height) or beside it (compact height): the away
    /// card, the Confirm stack, the running timer. Empty on most screens most of the time, and
    /// an empty column costs the stack nothing — `RootBottomOverlayLayout.size` spends no gap
    /// on a zero-height column.
    private var cards: some View {
        VStack(spacing: RootBottomOverlayLayout.spacing) {
            // A sprint that finished while the app was dead announces itself here — above the
            // tab bar on every tab, gone only when acknowledged.
            //
            // **Known collision, documented and deliberately unfixed (F-FocusCard-5).** This card
            // and the completion stack below share this column, so an old unacknowledged
            // app-was-dead completion and a new unconfirmed sprint can be on screen together in
            // two visual languages (green-washed v3 card above, material card below). E ruled the
            // offline card out of the focus-card arc explicitly — *"keep them separate... queue
            // it"* — and it fires only from `restorePersistedSprint()` after the process was
            // killed mid-sprint, a path E has never hit in normal use. Unifying the two is a
            // queued design question, not a defect to patch here.
            if let summary = focusService.offlineCompletionSummary {
                OfflineSprintSummaryCard(record: summary) {
                    focusService.acknowledgeOfflineCompletion()
                }
                .padding(.horizontal, 16)
            }

            // Sprints that finished naturally wait here for the user's Confirm — newest in front,
            // older ones peeking behind as edges (F-FocusCard-2, stacked in F-FocusCard-3).
            //
            // **Above the timer bar, deliberately.** E chose "Both show — new sprint runs": a
            // routine that auto-starts a sprint must never be dropped because the user had not
            // tidied up. So the running card keeps its established position at the bottom and
            // stays operable — a card behind another cannot be paused, and one under another
            // cannot be confirmed.
            //
            // The `if` is not decoration: the stack reserves top padding for the peeks its
            // `.offset`s hang outside its frame, and an empty stack rendered unconditionally
            // would spend that padding plus the column's own spacing on nothing.
            if !focusService.unconfirmedCompletions.isEmpty {
                FocusCompletionCardStack(
                    records: focusService.unconfirmedCompletions,
                    celebratingID: focusService.celebratingCompletionID
                ) { record in
                    Task { await focusService.confirmCompletion(record) }
                }
            }

            FocusTimerBar(service: focusService)
        }
    }
}

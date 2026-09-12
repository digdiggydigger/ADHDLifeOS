//
//  NudgesService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

@MainActor
final class NudgesService: ObservableObject {
    enum ListState: Equatable {
        case loading
        case loaded([Nudge])
        case failed(String)
    }

    @Published private(set) var state: ListState = .loading
    @Published var newLabel = ""
    @Published var newSchedule = NudgeSchedule(hour: 9, minute: 0, weekdays: Set(0...6))
    @Published private(set) var isCreating = false
    @Published var createErrorMessage: String?
    @Published var errorMessage: String?

    private let client: NudgesClientAdapting
    private let notificationSchedulingClient: NudgeNotificationSchedulingAdapting
    /// **The streak milestone's door** (`F-CTACelebrations-5`, E's F3 + R-b). The listener is the
    /// SERVICE's rather than the card's because both `NudgeDueCard` hosts — Today's section and the
    /// pushed `NudgesView` — share Today's one service, so a listener in the card would fire twice
    /// or once depending on which copy the user tapped. Defaulted inert, so every preview and every
    /// existing test builds this service unchanged.
    private let celebrate: any CelebrationRequesting

    init(
        client: NudgesClientAdapting,
        notificationSchedulingClient: NudgeNotificationSchedulingAdapting,
        celebrate: any CelebrationRequesting = InertCelebrationRequester()
    ) {
        self.client = client
        self.notificationSchedulingClient = notificationSchedulingClient
        self.celebrate = celebrate
    }

    var nudges: [Nudge] {
        if case .loaded(let nudges) = state {
            return nudges
        }
        return []
    }

    func dueNudges(now: Date = Date(), timeZone: TimeZone = .current) -> [Nudge] {
        nudges.filter { NudgeDueness.isNudgeDue(nudge: $0, now: now, timeZone: timeZone) }
    }

    var isNewLabelValid: Bool {
        if case .success = NudgeValidation.normalizeCreateNudgeInput(label: newLabel, schedule: newSchedule) {
            return true
        }
        return false
    }

    func load() async {
        // Quiet reload (SUGG-b4): only the FIRST load may show the loading state — once content
        // is on screen, a refetch (pull, or the app-wide DataChangeSignal) replaces it in place
        // instead of flashing it away.
        if case .loaded = state {} else { state = .loading }
        do {
            let nudges = try await client.fetchNudges()
            state = .loaded(nudges)
            await reconcileNotifications(nudges)
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    @discardableResult
    func createNudge() async -> Bool {
        createErrorMessage = nil

        let normalized: NormalizedCreateNudgeInput
        switch NudgeValidation.normalizeCreateNudgeInput(label: newLabel, schedule: newSchedule) {
        case .failure(let error):
            createErrorMessage = error.errorDescription
            return false
        case .success(let value):
            normalized = value
        }

        isCreating = true
        defer { isCreating = false }

        do {
            let created = try await client.createNudge(label: normalized.label, schedule: normalized.schedule)
            state = .loaded(nudges + [created])
            newLabel = ""
            if !(await scheduleOrCancelNotifications(for: created)) {
                let denialNote =
                    "Nudge created, but notifications permission was denied — nudge notifications were not scheduled."
                createErrorMessage = createErrorMessage.map { "\($0) \(denialNote)" } ?? denialNote
            }
            return true
        } catch {
            createErrorMessage = Self.message(for: error)
            return false
        }
    }

    @discardableResult
    func dismiss(_ nudge: Nudge) async -> Bool {
        errorMessage = nil
        do {
            let updated = try await client.markFired(
                id: nudge.id, existingCompletionDates: nudge.completionDates ?? []
            )
            replace(updated)
            return true
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }

    @discardableResult
    func update(nudge: Nudge, editedLabel: String, editedSchedule: NudgeSchedule) async -> Bool {
        errorMessage = nil

        switch NudgeValidation.normalizeUpdateNudgeInput(
            original: nudge, editedLabel: editedLabel, editedSchedule: editedSchedule
        ) {
        case .failure(let error):
            errorMessage = error.errorDescription
            return false
        case .success(let payload):
            guard !payload.isEmpty else { return true }
            return await applyUpdate(id: nudge.id, payload: payload)
        }
    }

    @discardableResult
    func toggleActive(_ nudge: Nudge) async -> Bool {
        errorMessage = nil
        var payload = NudgeUpdatePayload()
        payload.active = !nudge.active
        return await applyUpdate(id: nudge.id, payload: payload)
    }

    private func applyUpdate(id: UUID, payload: NudgeUpdatePayload) async -> Bool {
        do {
            let updated = try await client.updateNudge(id: id, payload: payload)
            replace(updated)
            if !(await scheduleOrCancelNotifications(for: updated)) {
                errorMessage = "Notifications permission denied — nudge notifications were not scheduled."
            }
            return true
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }

    private func replace(_ updated: Nudge) {
        state = .loaded(nudges.map { $0.id == updated.id ? updated : $0 })
    }

    /// Schedules `nudge`'s notifications if it's active (parsing its cron `schedule` string),
    /// or cancels any existing ones if it's inactive/unparseable. Returns `false` only when an
    /// active, parseable nudge's notifications couldn't be scheduled because permission was
    /// denied — callers surface that as a warning without treating the caller's own action as
    /// failed.
    @discardableResult
    private func scheduleOrCancelNotifications(for nudge: Nudge) async -> Bool {
        guard nudge.active, let schedule = NudgeSchedule.parse(cronString: nudge.schedule) else {
            await notificationSchedulingClient.cancelNotifications(nudgeId: nudge.id)
            return true
        }

        guard await notificationSchedulingClient.requestAuthorizationIfNeeded() else {
            return false
        }
        await notificationSchedulingClient.scheduleNotifications(
            nudgeId: nudge.id, label: nudge.label, schedule: schedule
        )
        return true
    }

    /// Reconciles every fetched nudge's local notification state to match its current
    /// `active`/`schedule`/`label` — necessary because the web client can edit these same rows
    /// without mobile's local notification schedule otherwise finding out.
    private func reconcileNotifications(_ nudges: [Nudge]) async {
        var permissionDenied = false
        for nudge in nudges where !(await scheduleOrCancelNotifications(for: nudge)) {
            permissionDenied = true
        }
        if permissionDenied {
            errorMessage = "Notifications permission denied — nudge notifications were not scheduled."
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

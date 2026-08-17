//
//  JournalService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

@MainActor
final class JournalService: ObservableObject {
    enum ListState: Equatable {
        case loading
        case loaded([Log])
        case failed(String)
    }

    @Published private(set) var state: ListState = .loading
    @Published var selectedLifeAreaId: UUID? {
        didSet {
            guard hasLoadedOnce else { return }
            recomputeFeed()
        }
    }
    @Published var composerBody = ""
    @Published var composerType: LogType = .log
    @Published var composerLifeAreaId: UUID?
    @Published private(set) var isCreating = false
    @Published var createErrorMessage: String?

    private let client: JournalClientAdapting
    private(set) var lifeAreas: [LifeArea] = []
    private var logs: [Log] = []
    private var hasLoadedOnce = false

    init(client: JournalClientAdapting) {
        self.client = client
    }

    var isComposerBodyValid: Bool {
        if case .success = LogValidation.normalizeCreateLogInput(
            body: composerBody, type: composerType, lifeAreaId: composerLifeAreaId
        ) {
            return true
        }
        return false
    }

    func load() async {
        state = .loading
        do {
            async let lifeAreasResult = client.fetchLifeAreas()
            async let logsResult = client.fetchLogs()
            lifeAreas = try await lifeAreasResult
            logs = try await logsResult
            hasLoadedOnce = true
            recomputeFeed()
        } catch {
            hasLoadedOnce = false
            state = .failed(Self.message(for: error))
        }
    }

    @discardableResult
    func createLog() async -> Bool {
        createErrorMessage = nil

        let normalized: NormalizedCreateLogInput
        switch LogValidation.normalizeCreateLogInput(
            body: composerBody, type: composerType, lifeAreaId: composerLifeAreaId
        ) {
        case .failure(let error):
            createErrorMessage = error.errorDescription
            return false
        case .success(let value):
            normalized = value
        }

        isCreating = true
        defer { isCreating = false }

        do {
            let created = try await client.createLog(normalized)
            logs.append(created)
            recomputeFeed()
            composerBody = ""
            composerType = .log
            composerLifeAreaId = nil
            return true
        } catch {
            createErrorMessage = Self.message(for: error)
            return false
        }
    }

    private func recomputeFeed() {
        let filtered = LogSorting.filterByLifeArea(logs, lifeAreaId: selectedLifeAreaId)
        state = .loaded(LogSorting.sortByEntryDateDescending(filtered))
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

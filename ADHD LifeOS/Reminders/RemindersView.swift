//
//  RemindersView.swift
//  ADHD LifeOS
//

import SwiftUI

struct RemindersView: View {
    @StateObject private var service: RemindersService

    init(client: RemindersClientAdapting) {
        _service = StateObject(wrappedValue: RemindersService(client: client))
    }

    var body: some View {
        Group {
            switch service.state {
            case .loading:
                ProgressView()
                    .accessibilityIdentifier("remindersLoadingIndicator")
            case .failed(let message):
                VStack(spacing: 12) {
                    Text("Couldn't load your reminders")
                        .font(.headline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .accessibilityIdentifier("remindersErrorMessage")
            case .loaded(let reminders):
                if reminders.isEmpty {
                    Text("No reminders yet")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("remindersEmptyState")
                } else {
                    List(reminders) { reminder in
                        ReminderRowView(reminder: reminder)
                    }
                }
            }
        }
        .navigationTitle("Reminders")
        .task {
            await service.load()
        }
    }
}

private struct ReminderRowView: View {
    let reminder: Reminder

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(reminder.title ?? "Untitled reminder")
                .font(.headline)
            HStack {
                Text(reminder.datetime.map(ReminderDateParsing.displayString) ?? "No date")
                Spacer()
                if let priority = reminder.priority {
                    Text(priority.rawValue.capitalized)
                }
                Text(reminder.type.rawValue.capitalized)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .accessibilityIdentifier("reminderRow-\(reminder.id)")
    }
}

#if DEBUG
private struct PreviewRemindersClientAdapting: RemindersClientAdapting {
    func fetchReminders() async throws -> [Reminder] {
        [
            Reminder(
                id: UUID().uuidString, type: .reminder, title: "LOW PRIORITY TEST",
                priority: .low, source: "poke",
                createdAt: Date(), datetime: Date()
            )
        ]
    }
}

#Preview {
    NavigationStack {
        RemindersView(client: PreviewRemindersClientAdapting())
    }
}
#endif

import SwiftUI
import SwiftData
import EventKit

/// The "which account does this belong to?" review flow. Apple Calendar
/// events can appear without the app's involvement (synced from another
/// device, added directly in the Calendar app, etc.), so this scans a
/// rolling window of Apple Calendar and lets the CSM link each unrecognized
/// event to an account and event type, or dismiss it for good.
struct UnlinkedEventsReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(EventKitManager.self) private var eventKitManager
    @Query private var trackedEvents: [Event]
    @Query private var ignoredEvents: [IgnoredCalendarEvent]
    @Query(sort: \Account.companyName) private var accounts: [Account]

    @State private var candidates: [EKEvent] = []
    @State private var eventPendingLink: IdentifiableEKEvent?

    var body: some View {
        NavigationStack {
            List {
                if candidates.isEmpty {
                    ContentUnavailableView(
                        "All Caught Up",
                        systemImage: "checkmark.circle",
                        description: Text("No Apple Calendar events are waiting to be linked to an account.")
                    )
                } else {
                    ForEach(candidates, id: \.eventIdentifier) { ekEvent in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(ekEvent.title ?? "Untitled Event").font(.headline)
                            Text(ekEvent.startDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack {
                                Button("Link to Account…") {
                                    eventPendingLink = IdentifiableEKEvent(event: ekEvent)
                                }
                                .buttonStyle(.borderedProminent)

                                Button("Ignore", role: .destructive) {
                                    ignore(ekEvent)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Link Calendar Events")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $eventPendingLink) { wrapper in
                LinkEventSheet(accounts: accounts) { account, type in
                    link(wrapper.event, to: account, as: type)
                }
            }
            .task { refresh() }
        }
    }

    private func refresh() {
        let known = Set(trackedEvents.compactMap(\.eventKitIdentifier))
            .union(ignoredEvents.map(\.eventKitIdentifier))
        let start = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let end = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        candidates = eventKitManager.fetchUnlinkedAppleCalendarEvents(
            from: start, to: end, knownEventKitIdentifiers: known
        )
    }

    private func link(_ ekEvent: EKEvent, to account: Account, as type: EventType) {
        let event = Event(type: type, title: ekEvent.title ?? type.rawValue, startDate: ekEvent.startDate)
        event.endDate = ekEvent.endDate
        event.account = account
        event.eventKitIdentifier = ekEvent.eventIdentifier
        event.isSyncedToEventKit = true
        if type == .other {
            event.customTypeLabel = ekEvent.title
        }
        modelContext.insert(event)
        try? modelContext.save()
        candidates.removeAll { $0.eventIdentifier == ekEvent.eventIdentifier }
        eventPendingLink = nil
    }

    private func ignore(_ ekEvent: EKEvent) {
        guard let identifier = ekEvent.eventIdentifier else { return }
        modelContext.insert(IgnoredCalendarEvent(eventKitIdentifier: identifier))
        try? modelContext.save()
        candidates.removeAll { $0.eventIdentifier == identifier }
    }
}

struct IdentifiableEKEvent: Identifiable {
    let event: EKEvent
    var id: String { event.eventIdentifier ?? UUID().uuidString }
}

private struct LinkEventSheet: View {
    @Environment(\.dismiss) private var dismiss
    let accounts: [Account]
    let onLink: (Account, EventType) -> Void

    @State private var selectedAccount: Account?
    @State private var selectedType: EventType = .other

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    Picker("Account", selection: $selectedAccount) {
                        Text("Choose…").tag(Account?.none)
                        ForEach(accounts) { account in
                            Text(account.companyName).tag(Optional(account))
                        }
                    }
                }
                Section("Event Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(EventType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Link Event")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Link") {
                        if let selectedAccount {
                            onLink(selectedAccount, selectedType)
                        }
                    }
                    .disabled(selectedAccount == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

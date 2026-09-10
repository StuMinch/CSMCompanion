import Foundation
import EventKit
import Observation

/// Owns the one `EKEventStore` for the app and handles both directions of
/// Calendar sync:
///   1. Writing our Events into Apple Calendar (`syncToAppleCalendar`).
///   2. Finding Apple Calendar events we don't already know about, so the
///      CSM can manually associate them with an account — see
///      `fetchUnlinkedAppleCalendarEvents` and `UnlinkedEventsReviewView`.
@Observable
final class EventKitManager {
    let store = EKEventStore()
    private(set) var authorizationStatus: EKAuthorizationStatus = .notDetermined

    init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    @discardableResult
    func requestAccess() async -> Bool {
        do {
            let granted = try await store.requestFullAccessToEvents()
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            return granted
        } catch {
            print("EventKit access request failed: \(error)")
            return false
        }
    }

    var isAuthorized: Bool {
        authorizationStatus == .fullAccess
    }

    // MARK: Writing our events into Apple Calendar

    /// Creates or updates the EKEvent mirroring this Event. Pass `recurrence`
    /// for a recurring Cadence Call so Apple Calendar shows every occurrence.
    @discardableResult
    func syncToAppleCalendar(event: Event, recurrence: RecurrenceRule? = nil) -> String? {
        guard isAuthorized else { return nil }

        let ekEvent: EKEvent
        if let identifier = event.eventKitIdentifier,
           let existing = store.event(withIdentifier: identifier) {
            ekEvent = existing
        } else {
            ekEvent = EKEvent(eventStore: store)
            ekEvent.calendar = store.defaultCalendarForNewEvents
                ?? store.calendars(for: .event).first(where: { $0.allowsContentModifications })
        }

        ekEvent.title = event.title.isEmpty ? event.type.rawValue : event.title
        ekEvent.startDate = event.startDate
        ekEvent.endDate = event.endDate ?? event.startDate.addingTimeInterval(60 * 60)
        ekEvent.notes = "CSM Companion — \(event.type.rawValue)"
            + (event.account.map { " for \($0.companyName)" } ?? "")
        // Tags the event as ours so it's recognizable if seen again elsewhere.
        ekEvent.url = URL(string: "csmcompanion://event/\(event.id.uuidString)")

        if let recurrence {
            ekEvent.recurrenceRules = [ekRecurrenceRule(from: recurrence)]
        } else {
            ekEvent.recurrenceRules = nil
        }

        do {
            try store.save(ekEvent, span: .thisEvent)
            event.eventKitIdentifier = ekEvent.eventIdentifier
            event.isSyncedToEventKit = true
            return ekEvent.eventIdentifier
        } catch {
            print("Failed to save EKEvent: \(error)")
            return nil
        }
    }

    func removeFromAppleCalendar(event: Event) {
        guard let identifier = event.eventKitIdentifier,
              let ekEvent = store.event(withIdentifier: identifier) else { return }
        try? store.remove(ekEvent, span: .thisEvent)
        event.eventKitIdentifier = nil
        event.isSyncedToEventKit = false
    }

    private func ekRecurrenceRule(from rule: RecurrenceRule) -> EKRecurrenceRule {
        switch rule.frequency {
        case .weekly:
            return EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, end: nil)
        case .biweekly:
            return EKRecurrenceRule(recurrenceWith: .weekly, interval: 2, end: nil)
        case .monthly:
            return EKRecurrenceRule(recurrenceWith: .monthly, interval: 1, end: nil)
        case .custom:
            return EKRecurrenceRule(recurrenceWith: .weekly, interval: max(rule.intervalWeeks, 1), end: nil)
        }
    }

    // MARK: Finding Apple Calendar events that aren't linked to an account yet

    /// Returns EKEvents in the given range that aren't already tracked as one
    /// of our Events (by `eventKitIdentifier`) or previously dismissed.
    /// Candidates the CSM should manually link to an account, or ignore.
    func fetchUnlinkedAppleCalendarEvents(
        from startDate: Date,
        to endDate: Date,
        knownEventKitIdentifiers: Set<String>
    ) -> [EKEvent] {
        guard isAuthorized else { return [] }
        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = store.events(matching: predicate)
        return events.filter { !knownEventKitIdentifiers.contains($0.eventIdentifier ?? "") }
    }
}

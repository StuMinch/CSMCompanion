import Foundation
import SwiftData

enum EventType: String, Codable, CaseIterable, Identifiable {
    case ebr = "EBR"
    case qbr = "QBR"
    case cadenceCall = "Cadence Call"
    case renewal = "Renewal"
    case other = "Other"

    var id: String { rawValue }
}

@Model
final class Event {
    var id: UUID = UUID()
    var account: Account?

    var typeRaw: String = EventType.other.rawValue
    var customTypeLabel: String?
    var title: String = ""
    var startDate: Date = Date()
    var endDate: Date?

    var isCompleted: Bool = false
    var completedDate: Date?
    var outcomeNotes: String?

    /// True when this event mirrors one of the EBR/QBR/Cadence/Renewal dates
    /// set directly on the Account (as opposed to one added from the
    /// Calendar tab's "Add Event" button, or one linked in from an existing
    /// Apple Calendar event). Lets editing an account update the same event
    /// instead of creating a duplicate.
    var createdFromAccountDates: Bool = false

    /// True when this is a recurring Cadence Call series. EventKit stores
    /// the actual recurrence rule; this flag just lets the UI label it.
    var isRecurringCadence: Bool = false

    // MARK: EventKit sync
    var eventKitIdentifier: String?
    var isSyncedToEventKit: Bool = false

    // MARK: Notification bookkeeping (so reminders can be cancelled/rescheduled)
    private var scheduledNotificationIdentifiersData: Data?

    var createdDate: Date = Date()

    init(type: EventType, title: String, startDate: Date) {
        self.typeRaw = type.rawValue
        self.title = title
        self.startDate = startDate
    }

    var type: EventType {
        get { EventType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }

    var scheduledNotificationIdentifiers: [String] {
        get {
            guard let data = scheduledNotificationIdentifiersData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            scheduledNotificationIdentifiersData = try? JSONEncoder().encode(newValue)
        }
    }
}

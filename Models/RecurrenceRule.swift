import Foundation

/// A lightweight recurrence description for a recurring Cadence Call. Kept
/// intentionally simple (weekly / biweekly / monthly / custom-every-N-weeks)
/// rather than modeling the full richness of EventKit's `EKRecurrenceRule`,
/// since that's what actually gets constructed when syncing to Apple
/// Calendar — see `EventKitManager.ekRecurrenceRule(from:)`.
struct RecurrenceRule: Codable, Equatable {
    enum Frequency: String, Codable, CaseIterable, Identifiable {
        case weekly, biweekly, monthly, custom
        var id: String { rawValue }
    }

    var frequency: Frequency
    /// Only meaningful when `frequency == .custom` — "every N weeks".
    var intervalWeeks: Int
    var weekday: Int?
    var startDate: Date
}

import Foundation
import SwiftData

/// Records an Apple Calendar event the CSM explicitly dismissed from the
/// "Link Calendar Events" review flow, so it isn't re-surfaced every time
/// the app re-scans Apple Calendar for unlinked events.
@Model
final class IgnoredCalendarEvent {
    var eventKitIdentifier: String = ""
    var ignoredDate: Date = Date()

    init(eventKitIdentifier: String) {
        self.eventKitIdentifier = eventKitIdentifier
    }
}

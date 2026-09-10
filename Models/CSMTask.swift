import Foundation
import SwiftData

/// Named `CSMTask` (not `Task`) to avoid colliding with Swift's own
/// concurrency `Task` type.
@Model
final class CSMTask {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String?
    var account: Account?
    var dueDate: Date?
    var isCompleted: Bool = false
    var completedDate: Date?

    /// Cleared tasks are hidden from the default Tasks list but never
    /// deleted, so they remain queryable for reporting/history.
    var isCleared: Bool = false
    var createdDate: Date = Date()

    var scheduledNotificationIdentifier: String?

    init(title: String) {
        self.title = title
    }
}

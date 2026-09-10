import Foundation
import UserNotifications

/// Schedules and cancels the local reminder notifications for Events and
/// Tasks, based on the user-editable `ReminderCascadeSettings`.
///
/// TODO (noted in SPEC.md §5.3, not built in v1): iOS has a practical ~64
/// pending-notification-request budget. This implementation schedules every
/// "days before" reminder as its own request, which is simplest to reason
/// about but could approach that ceiling for a CSM with a large book of
/// accounts and full cascades on every event. A follow-up could instead
/// schedule only the next upcoming reminder per event and reschedule the
/// next one as each fires (e.g. from `UNUserNotificationCenterDelegate`).
enum NotificationManager {
    @discardableResult
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Notification authorization failed: \(error)")
            return false
        }
    }

    /// Cancels any previously scheduled reminders for this event, then
    /// schedules the current cascade — safe to call whenever the event's
    /// date changes or the cascade settings are edited.
    static func rescheduleReminders(for event: Event, settings: ReminderCascadeSettings) {
        cancelReminders(for: event)
        guard !event.isCompleted else { return }

        let daysBefore = settings.days(for: event.type)
        guard !daysBefore.isEmpty else { return }

        var newIdentifiers: [String] = []
        let calendar = Calendar.current

        for day in daysBefore {
            guard let fireDate = calendar.date(byAdding: .day, value: -day, to: event.startDate),
                  fireDate > Date() else { continue }

            let identifier = "event-\(event.id.uuidString)-\(day)d"
            let content = UNMutableNotificationContent()
            content.title = title(for: event)
            content.body = body(daysBefore: day)
            content.sound = .default
            content.userInfo = ["eventId": event.id.uuidString]

            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request)
            newIdentifiers.append(identifier)
        }

        event.scheduledNotificationIdentifiers = newIdentifiers
    }

    static func cancelReminders(for event: Event) {
        let identifiers = event.scheduledNotificationIdentifiers
        guard !identifiers.isEmpty else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        event.scheduledNotificationIdentifiers = []
    }

    static func scheduleReminder(for task: CSMTask) {
        cancelReminder(for: task)
        guard let dueDate = task.dueDate, dueDate > Date(), !task.isCompleted else { return }

        let identifier = "task-\(task.id.uuidString)"
        let content = UNMutableNotificationContent()
        content.title = "Task due"
        content.body = task.title
        content.sound = .default
        content.userInfo = ["taskId": task.id.uuidString]

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        task.scheduledNotificationIdentifier = identifier
    }

    static func cancelReminder(for task: CSMTask) {
        guard let identifier = task.scheduledNotificationIdentifier else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        task.scheduledNotificationIdentifier = nil
    }

    private static func title(for event: Event) -> String {
        let accountName = event.account?.companyName ?? "Unassigned account"
        if event.type == .other {
            return "\(event.customTypeLabel ?? "Event") — \(accountName)"
        }
        return "\(event.type.rawValue) — \(accountName)"
    }

    private static func body(daysBefore: Int) -> String {
        switch daysBefore {
        case 0: return "Today"
        case 1: return "Tomorrow"
        default: return "In \(daysBefore) days"
        }
    }
}

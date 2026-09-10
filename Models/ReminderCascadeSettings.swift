import Foundation
import SwiftData

/// A single editable record holding the "days before" reminder cascade for
/// each event type. Exactly one instance is expected to exist; call sites
/// fetch the first result of `@Query private var settings: [ReminderCascadeSettings]`
/// and create one on first use if the query comes back empty (see
/// `SettingsView` and `AddEditAccountView` for that pattern).
@Model
final class ReminderCascadeSettings {
    var id: UUID = UUID()

    private var renewalDaysBeforeData: Data = Data()
    private var ebrDaysBeforeData: Data = Data()
    private var qbrDaysBeforeData: Data = Data()
    private var cadenceCallDaysBeforeData: Data = Data()

    init() {
        renewalDaysBefore = [180, 120, 90, 60, 30]
        ebrDaysBefore = [30, 14, 7, 1]
        qbrDaysBefore = [30, 14, 7, 1]
        cadenceCallDaysBefore = [7, 1]
    }

    var renewalDaysBefore: [Int] {
        get { (try? JSONDecoder().decode([Int].self, from: renewalDaysBeforeData)) ?? [180, 120, 90, 60, 30] }
        set { renewalDaysBeforeData = (try? JSONEncoder().encode(newValue)) ?? renewalDaysBeforeData }
    }

    var ebrDaysBefore: [Int] {
        get { (try? JSONDecoder().decode([Int].self, from: ebrDaysBeforeData)) ?? [30, 14, 7, 1] }
        set { ebrDaysBeforeData = (try? JSONEncoder().encode(newValue)) ?? ebrDaysBeforeData }
    }

    var qbrDaysBefore: [Int] {
        get { (try? JSONDecoder().decode([Int].self, from: qbrDaysBeforeData)) ?? [30, 14, 7, 1] }
        set { qbrDaysBeforeData = (try? JSONEncoder().encode(newValue)) ?? qbrDaysBeforeData }
    }

    var cadenceCallDaysBefore: [Int] {
        get { (try? JSONDecoder().decode([Int].self, from: cadenceCallDaysBeforeData)) ?? [7, 1] }
        set { cadenceCallDaysBeforeData = (try? JSONEncoder().encode(newValue)) ?? cadenceCallDaysBeforeData }
    }

    func days(for type: EventType) -> [Int] {
        switch type {
        case .renewal: return renewalDaysBefore
        case .ebr: return ebrDaysBefore
        case .qbr: return qbrDaysBefore
        case .cadenceCall: return cadenceCallDaysBefore
        case .other: return []
        }
    }
}

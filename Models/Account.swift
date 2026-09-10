import Foundation
import SwiftData

@Model
final class Account {
    var id: UUID = UUID()
    var companyName: String = ""
    var industry: String?
    var primaryContactName: String?
    var primaryContactEmail: String?
    var notes: String = ""

    var ebrDate: Date?
    var qbrDate: Date?

    var cadenceIsRecurring: Bool = false
    var cadenceSingleDate: Date?
    var cadenceRecurrenceData: Data?

    var renewalDate: Date?

    var healthStatusRaw: String = AccountHealth.active.rawValue
    var isArchived: Bool = false
    var createdDate: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Event.account)
    var events: [Event]? = []

    @Relationship(deleteRule: .cascade, inverse: \CSMTask.account)
    var tasks: [CSMTask]? = []

    @Relationship(deleteRule: .cascade, inverse: \NewsItem.account)
    var newsItems: [NewsItem]? = []

    init(companyName: String) {
        self.companyName = companyName
    }

    var healthStatus: AccountHealth {
        get { AccountHealth(rawValue: healthStatusRaw) ?? .active }
        set { healthStatusRaw = newValue.rawValue }
    }

    /// Only meaningful when `cadenceIsRecurring == true`; encoded as Data so
    /// SwiftData/CloudKit doesn't need a separate model for it.
    var cadenceRecurrenceRule: RecurrenceRule? {
        get {
            guard let data = cadenceRecurrenceData else { return nil }
            return try? JSONDecoder().decode(RecurrenceRule.self, from: data)
        }
        set {
            cadenceRecurrenceData = try? JSONEncoder().encode(newValue)
        }
    }
}

import Foundation

enum AccountHealth: String, Codable, CaseIterable, Identifiable {
    case active = "Active"
    case atRisk = "At Risk"
    case churned = "Churned"
    case renewed = "Renewed"

    var id: String { rawValue }
}

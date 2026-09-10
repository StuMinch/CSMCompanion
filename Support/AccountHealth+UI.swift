import SwiftUI

extension AccountHealth {
    var color: Color {
        switch self {
        case .active: return .green
        case .atRisk: return .orange
        case .churned: return .red
        case .renewed: return .blue
        }
    }
}

import SwiftUI

extension EventType {
    var color: Color {
        switch self {
        case .ebr: return .purple
        case .qbr: return .blue
        case .cadenceCall: return .teal
        case .renewal: return .red
        case .other: return .gray
        }
    }
}

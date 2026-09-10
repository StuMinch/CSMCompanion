import CloudKit

enum ICloudStatus: Equatable {
    case available
    case noAccount
    case restricted
    case couldNotDetermine
    case temporarilyUnavailable

    var userMessage: String {
        switch self {
        case .available:
            return "iCloud is available."
        case .noAccount:
            return "CSM Companion needs an iCloud account to store your data. Please sign in to iCloud in Settings, then come back."
        case .restricted:
            return "iCloud access is restricted on this device (for example by a management profile), so CSM Companion can't store your data here."
        case .couldNotDetermine:
            return "We couldn't determine your iCloud account status. Please check your network connection and try again."
        case .temporarilyUnavailable:
            return "iCloud is temporarily unavailable. Please try again shortly."
        }
    }
}

enum CloudKitStatusChecker {
    static func currentStatus() async -> ICloudStatus {
        do {
            let status = try await CKContainer.default().accountStatus()
            switch status {
            case .available: return .available
            case .noAccount: return .noAccount
            case .restricted: return .restricted
            case .couldNotDetermine: return .couldNotDetermine
            case .temporarilyUnavailable: return .temporarilyUnavailable
            @unknown default: return .couldNotDetermine
            }
        } catch {
            return .couldNotDetermine
        }
    }
}

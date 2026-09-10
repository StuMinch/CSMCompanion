import SwiftUI

/// App root: gates the whole experience behind an iCloud availability check
/// (CloudKit sync requires a signed-in iCloud account), then requests
/// EventKit + notification permissions once iCloud is confirmed available.
struct RootView: View {
    @State private var iCloudStatus: ICloudStatus?
    @State private var eventKitManager = EventKitManager()

    var body: some View {
        Group {
            switch iCloudStatus {
            case .none:
                ProgressView("Checking iCloud status…")
            case .available:
                MainTabView()
                    .environment(eventKitManager)
            case .some(let status):
                ICloudGateView(status: status, onRetry: checkStatus)
            }
        }
        .task { await bootstrap() }
    }

    private func bootstrap() async {
        await checkStatus()
        if iCloudStatus == .available {
            _ = await eventKitManager.requestAccess()
            _ = await NotificationManager.requestAuthorization()
        }
    }

    private func checkStatus() async {
        iCloudStatus = await CloudKitStatusChecker.currentStatus()
    }
}

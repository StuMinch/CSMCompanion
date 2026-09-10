import SwiftUI

struct ICloudGateView: View {
    let status: ICloudStatus
    let onRetry: () async -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("iCloud Required")
                .font(.title2.bold())
            Text(status.userMessage)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Try Again") {
                Task { await onRetry() }
            }
        }
        .padding()
    }
}

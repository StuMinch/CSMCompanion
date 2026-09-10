import SwiftUI
import SwiftData

/// Simple "reassign this event's account" picker, used from EventDetailView.
/// For linking a brand-new (previously unlinked) Apple Calendar event, see
/// `UnlinkedEventsReviewView`'s own account+type picker instead.
struct AccountPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Account.companyName) private var accounts: [Account]
    @Binding var selection: Account?

    var body: some View {
        NavigationStack {
            List {
                Button("Not associated with an account") {
                    selection = nil
                    dismiss()
                }
                .foregroundStyle(.primary)

                ForEach(accounts) { account in
                    Button {
                        selection = account
                        dismiss()
                    } label: {
                        HStack {
                            Text(account.companyName)
                            Spacer()
                            if selection == account {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle("Assign Account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

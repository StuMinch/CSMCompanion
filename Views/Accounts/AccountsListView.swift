import SwiftUI
import SwiftData

struct AccountsListView: View {
    @Query(filter: #Predicate<Account> { !$0.isArchived }, sort: \Account.companyName)
    private var accounts: [Account]

    @State private var isPresentingAddAccount = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(accounts) { account in
                    NavigationLink(value: account) {
                        AccountRow(account: account)
                    }
                }
            }
            .navigationTitle("Accounts")
            .navigationDestination(for: Account.self) { account in
                AccountDetailView(account: account)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingAddAccount = true
                    } label: {
                        Label("Add Account", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddAccount) {
                AddEditAccountView(account: nil)
            }
            .overlay {
                if accounts.isEmpty {
                    ContentUnavailableView(
                        "No Accounts Yet",
                        systemImage: "building.2",
                        description: Text("Tap + to add your first account.")
                    )
                }
            }
        }
    }
}

struct AccountRow: View {
    let account: Account

    var body: some View {
        HStack {
            Circle()
                .fill(account.healthStatus.color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading) {
                Text(account.companyName).font(.headline)
                if let industry = account.industry, !industry.isEmpty {
                    Text(industry).font(.subheadline).foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let renewal = account.renewalDate {
                Text(renewal, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

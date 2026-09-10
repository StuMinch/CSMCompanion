import SwiftUI
import SwiftData

/// UI and data model for the News tab are in place; there is no live news
/// source wired up yet (see SPEC.md §5.2/§8.1 for the source options to
/// evaluate). Populate `NewsItem` records from whatever source is chosen
/// and this view will display them.
struct NewsFeedView: View {
    @Query(sort: \NewsItem.publishedDate, order: .reverse) private var newsItems: [NewsItem]
    @Query(sort: \Account.companyName) private var accounts: [Account]

    @State private var filterAccount: Account?

    private var filteredItems: [NewsItem] {
        guard let filterAccount else { return newsItems }
        return newsItems.filter { $0.account == filterAccount }
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredItems.isEmpty {
                    ContentUnavailableView(
                        "No News Yet",
                        systemImage: "newspaper",
                        description: Text("News about your accounts will appear here once a news source is connected. See SPEC.md §5.2 for source options to wire up.")
                    )
                } else {
                    ForEach(filteredItems) { item in
                        Link(destination: item.url ?? URL(string: "https://example.com")!) {
                            VStack(alignment: .leading, spacing: 4) {
                                if let account = item.account {
                                    Text(account.companyName.uppercased())
                                        .font(.caption2.bold())
                                        .foregroundStyle(.secondary)
                                }
                                Text(item.headline)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("\(item.sourceName) · \(item.publishedDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("News")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("All Accounts") { filterAccount = nil }
                        ForEach(accounts) { account in
                            Button(account.companyName) { filterAccount = account }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
}

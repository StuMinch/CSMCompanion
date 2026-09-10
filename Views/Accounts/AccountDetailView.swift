import SwiftUI
import SwiftData

struct AccountDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var account: Account
    @State private var isPresentingEdit = false

    private var completedEvents: [Event] {
        (account.events ?? [])
            .filter(\.isCompleted)
            .sorted { ($0.completedDate ?? $0.startDate) > ($1.completedDate ?? $1.startDate) }
    }

    private var upcomingEvents: [Event] {
        (account.events ?? [])
            .filter { !$0.isCompleted }
            .sorted { $0.startDate < $1.startDate }
    }

    private var openTasks: [CSMTask] {
        (account.tasks ?? []).filter { !$0.isCompleted }
    }

    private var completedTasks: [CSMTask] {
        (account.tasks ?? []).filter { $0.isCompleted && !$0.isCleared }
    }

    var body: some View {
        List {
            Section("Overview") {
                LabeledContent("Industry", value: account.industry ?? "—")
                LabeledContent("Contact", value: account.primaryContactName ?? "—")
                Picker("Health", selection: $account.healthStatus) {
                    ForEach(AccountHealth.allCases) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                if !account.notes.isEmpty {
                    Text(account.notes).font(.callout).foregroundStyle(.secondary)
                }
            }

            Section("Upcoming") {
                if upcomingEvents.isEmpty {
                    Text("Nothing scheduled").foregroundStyle(.secondary)
                } else {
                    ForEach(upcomingEvents) { event in
                        NavigationLink(value: event) {
                            EventRow(event: event)
                        }
                    }
                }
            }

            Section("Tasks") {
                if openTasks.isEmpty && completedTasks.isEmpty {
                    Text("No tasks yet").foregroundStyle(.secondary)
                } else {
                    ForEach(openTasks) { task in
                        TaskRow(task: task)
                    }
                    ForEach(completedTasks) { task in
                        TaskRow(task: task)
                    }
                }
            }

            Section("History (for reporting)") {
                if completedEvents.isEmpty {
                    Text("No completed reviews or calls yet").foregroundStyle(.secondary)
                } else {
                    ForEach(completedEvents) { event in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(event.type.rawValue) — \(event.completedDate?.formatted(date: .abbreviated, time: .omitted) ?? "")")
                                .font(.subheadline.bold())
                            if let notes = event.outcomeNotes, !notes.isEmpty {
                                Text(notes).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section {
                Button(account.isArchived ? "Unarchive Account" : "Archive Account") {
                    account.isArchived.toggle()
                }
            }
        }
        .navigationTitle(account.companyName)
        .navigationDestination(for: Event.self) { event in
            EventDetailView(event: event)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { isPresentingEdit = true }
            }
        }
        .sheet(isPresented: $isPresentingEdit) {
            AddEditAccountView(account: account)
        }
    }
}

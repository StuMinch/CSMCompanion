import SwiftUI
import SwiftData

struct AddEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(EventKitManager.self) private var eventKitManager
    @Query(sort: \Account.companyName) private var accounts: [Account]
    @Query private var cascadeSettingsQuery: [ReminderCascadeSettings]

    let defaultDate: Date

    @State private var type: EventType = .cadenceCall
    @State private var customLabel = ""
    @State private var selectedAccount: Account?
    @State private var startDate: Date
    @State private var addToAppleCalendar = true

    init(defaultDate: Date) {
        self.defaultDate = defaultDate
        _startDate = State(initialValue: defaultDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Event Type") {
                    Picker("Type", selection: $type) {
                        ForEach(EventType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.inline)

                    if type == .other {
                        TextField("Custom event name", text: $customLabel)
                    }
                }

                Section("Account") {
                    Picker("Account", selection: $selectedAccount) {
                        Text("None").tag(Account?.none)
                        ForEach(accounts) { account in
                            Text(account.companyName).tag(Optional(account))
                        }
                    }
                }

                Section("Date & Time") {
                    DatePicker("Starts", selection: $startDate)
                }

                Section {
                    Toggle("Add to Apple Calendar", isOn: $addToAppleCalendar)
                }
            }
            .navigationTitle("New Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func save() {
        let title = (type == .other && !customLabel.isEmpty)
            ? customLabel
            : "\(type.rawValue)" + (selectedAccount.map { " — \($0.companyName)" } ?? "")

        let event = Event(type: type, title: title, startDate: startDate)
        event.customTypeLabel = type == .other ? customLabel : nil
        event.account = selectedAccount
        modelContext.insert(event)

        if addToAppleCalendar {
            eventKitManager.syncToAppleCalendar(event: event)
        }

        let settings = cascadeSettingsQuery.first ?? {
            let created = ReminderCascadeSettings()
            modelContext.insert(created)
            return created
        }()
        NotificationManager.rescheduleReminders(for: event, settings: settings)

        try? modelContext.save()
        dismiss()
    }
}

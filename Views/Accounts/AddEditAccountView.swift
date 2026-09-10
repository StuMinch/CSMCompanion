import SwiftUI
import SwiftData

struct AddEditAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(EventKitManager.self) private var eventKitManager
    @Query private var cascadeSettingsQuery: [ReminderCascadeSettings]

    /// Pass nil to create a new account, or an existing Account to edit it.
    let account: Account?

    @State private var companyName = ""
    @State private var industry = ""
    @State private var primaryContactName = ""
    @State private var primaryContactEmail = ""
    @State private var notes = ""
    @State private var healthStatus: AccountHealth = .active

    @State private var hasEBR = false
    @State private var ebrDate = Date().addingTimeInterval(60 * 60 * 24 * 30)

    @State private var hasQBR = false
    @State private var qbrDate = Date().addingTimeInterval(60 * 60 * 24 * 90)

    @State private var hasCadence = false
    @State private var cadenceIsRecurring = true
    @State private var cadenceDate = Date().addingTimeInterval(60 * 60 * 24 * 14)
    @State private var cadenceFrequency: RecurrenceRule.Frequency = .biweekly
    @State private var cadenceIntervalWeeks = 2

    @State private var hasRenewal = false
    @State private var renewalDate = Date().addingTimeInterval(60 * 60 * 24 * 365)

    @State private var syncToAppleCalendar = true

    private var isEditing: Bool { account != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Company") {
                    TextField("Company Name", text: $companyName)
                    TextField("Industry", text: $industry)
                    Picker("Health", selection: $healthStatus) {
                        ForEach(AccountHealth.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }

                Section("Primary Contact") {
                    TextField("Name", text: $primaryContactName)
                    TextField("Email", text: $primaryContactEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }

                Section("Notes") {
                    TextEditor(text: $notes).frame(minHeight: 80)
                }

                Section("Key Dates") {
                    Toggle("Executive Business Review (EBR)", isOn: $hasEBR)
                    if hasEBR {
                        DatePicker("EBR Date", selection: $ebrDate)
                    }

                    Toggle("Quarterly Business Review (QBR)", isOn: $hasQBR)
                    if hasQBR {
                        DatePicker("QBR Date", selection: $qbrDate)
                    }

                    Toggle("Cadence Call", isOn: $hasCadence)
                    if hasCadence {
                        Picker("Type", selection: $cadenceIsRecurring) {
                            Text("Recurring").tag(true)
                            Text("One-time").tag(false)
                        }
                        .pickerStyle(.segmented)

                        if cadenceIsRecurring {
                            Picker("Frequency", selection: $cadenceFrequency) {
                                ForEach(RecurrenceRule.Frequency.allCases) { freq in
                                    Text(freq.rawValue.capitalized).tag(freq)
                                }
                            }
                            if cadenceFrequency == .custom {
                                Stepper("Every \(cadenceIntervalWeeks) weeks", value: $cadenceIntervalWeeks, in: 1...12)
                            }
                            DatePicker("First Call", selection: $cadenceDate)
                        } else {
                            DatePicker("Call Date", selection: $cadenceDate)
                        }
                    }

                    Toggle("Renewal", isOn: $hasRenewal)
                    if hasRenewal {
                        DatePicker("Renewal Date", selection: $renewalDate)
                    }
                }

                Section {
                    Toggle("Add to Apple Calendar", isOn: $syncToAppleCalendar)
                } footer: {
                    Text("Events created from the dates above are added to Apple Calendar and their reminder cascade is scheduled automatically.")
                }
            }
            .navigationTitle(isEditing ? "Edit Account" : "New Account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(companyName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: populateIfEditing)
        }
    }

    private func populateIfEditing() {
        guard let account else { return }
        companyName = account.companyName
        industry = account.industry ?? ""
        primaryContactName = account.primaryContactName ?? ""
        primaryContactEmail = account.primaryContactEmail ?? ""
        notes = account.notes
        healthStatus = account.healthStatus

        if let date = account.ebrDate { hasEBR = true; ebrDate = date }
        if let date = account.qbrDate { hasQBR = true; qbrDate = date }
        if let date = account.renewalDate { hasRenewal = true; renewalDate = date }

        if account.cadenceSingleDate != nil || account.cadenceRecurrenceRule != nil {
            hasCadence = true
            cadenceIsRecurring = account.cadenceIsRecurring
            if let rule = account.cadenceRecurrenceRule {
                cadenceFrequency = rule.frequency
                cadenceIntervalWeeks = rule.intervalWeeks
                cadenceDate = rule.startDate
            } else if let date = account.cadenceSingleDate {
                cadenceDate = date
            }
        }
    }

    private func save() {
        let targetAccount = account ?? Account(companyName: companyName)
        targetAccount.companyName = companyName
        targetAccount.industry = industry.isEmpty ? nil : industry
        targetAccount.primaryContactName = primaryContactName.isEmpty ? nil : primaryContactName
        targetAccount.primaryContactEmail = primaryContactEmail.isEmpty ? nil : primaryContactEmail
        targetAccount.notes = notes
        targetAccount.healthStatus = healthStatus

        targetAccount.ebrDate = hasEBR ? ebrDate : nil
        targetAccount.qbrDate = hasQBR ? qbrDate : nil
        targetAccount.renewalDate = hasRenewal ? renewalDate : nil

        targetAccount.cadenceIsRecurring = hasCadence ? cadenceIsRecurring : false
        if hasCadence && cadenceIsRecurring {
            targetAccount.cadenceRecurrenceRule = RecurrenceRule(
                frequency: cadenceFrequency,
                intervalWeeks: cadenceFrequency == .custom ? cadenceIntervalWeeks : 1,
                weekday: nil,
                startDate: cadenceDate
            )
            targetAccount.cadenceSingleDate = nil
        } else if hasCadence {
            targetAccount.cadenceSingleDate = cadenceDate
            targetAccount.cadenceRecurrenceRule = nil
        } else {
            targetAccount.cadenceSingleDate = nil
            targetAccount.cadenceRecurrenceRule = nil
        }

        if account == nil {
            modelContext.insert(targetAccount)
        }

        let settings = cascadeSettingsQuery.first ?? {
            let created = ReminderCascadeSettings()
            modelContext.insert(created)
            return created
        }()

        // Create/update the Event tied to each configured date so the
        // Calendar tab, Apple Calendar, notifications, and the account's
        // reporting history all stay in sync.
        upsertEvent(type: .ebr, date: hasEBR ? ebrDate : nil, on: targetAccount, settings: settings)
        upsertEvent(type: .qbr, date: hasQBR ? qbrDate : nil, on: targetAccount, settings: settings)
        upsertEvent(type: .renewal, date: hasRenewal ? renewalDate : nil, on: targetAccount, settings: settings)

        if hasCadence {
            upsertEvent(
                type: .cadenceCall,
                date: cadenceDate,
                on: targetAccount,
                settings: settings,
                isRecurring: cadenceIsRecurring
            )
        } else {
            upsertEvent(type: .cadenceCall, date: nil, on: targetAccount, settings: settings)
        }

        try? modelContext.save()
        dismiss()
    }

    /// Finds (or creates) the Event of the given type that was auto-created
    /// from this account's dates, and updates its date/recurrence, then
    /// syncs it to Apple Calendar and reschedules its reminder cascade.
    /// Passing `date == nil` removes that event entirely.
    private func upsertEvent(
        type: EventType,
        date: Date?,
        on account: Account,
        settings: ReminderCascadeSettings,
        isRecurring: Bool = false
    ) {
        let existing = (account.events ?? []).first { $0.type == type && $0.createdFromAccountDates }

        guard let date else {
            if let existing {
                NotificationManager.cancelReminders(for: existing)
                if existing.isSyncedToEventKit {
                    eventKitManager.removeFromAppleCalendar(event: existing)
                }
                modelContext.delete(existing)
            }
            return
        }

        let event = existing ?? {
            let newEvent = Event(type: type, title: "", startDate: date)
            newEvent.createdFromAccountDates = true
            newEvent.account = account
            modelContext.insert(newEvent)
            return newEvent
        }()

        event.startDate = date
        event.title = "\(type.rawValue) — \(account.companyName)"
        event.isRecurringCadence = isRecurring

        if syncToAppleCalendar {
            eventKitManager.syncToAppleCalendar(
                event: event,
                recurrence: isRecurring ? account.cadenceRecurrenceRule : nil
            )
        }

        NotificationManager.rescheduleReminders(for: event, settings: settings)
    }
}

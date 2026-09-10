import SwiftUI
import SwiftData

struct AddEditTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Account.companyName) private var accounts: [Account]

    let task: CSMTask?

    @State private var title = ""
    @State private var notes = ""
    @State private var selectedAccount: Account?
    @State private var hasDueDate = false
    @State private var dueDate = Date().addingTimeInterval(60 * 60 * 24)

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                    TextEditor(text: $notes).frame(minHeight: 60)
                }

                Section("Linked Account") {
                    Picker("Account", selection: $selectedAccount) {
                        Text("None").tag(Account?.none)
                        ForEach(accounts) { account in
                            Text(account.companyName).tag(Optional(account))
                        }
                    }
                }

                Section("Due Date") {
                    Toggle("Set a deadline", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate)
                        Text("Tasks with a deadline also appear on the Calendar tab.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
            .onAppear(perform: populate)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(title.isEmpty)
                }
            }
        }
    }

    private func populate() {
        guard let task else { return }
        title = task.title
        notes = task.notes ?? ""
        selectedAccount = task.account
        if let due = task.dueDate {
            hasDueDate = true
            dueDate = due
        }
    }

    private func save() {
        let target = task ?? CSMTask(title: title)
        target.title = title
        target.notes = notes.isEmpty ? nil : notes
        target.account = selectedAccount
        target.dueDate = hasDueDate ? dueDate : nil

        if task == nil {
            modelContext.insert(target)
        }

        if hasDueDate {
            NotificationManager.scheduleReminder(for: target)
        } else {
            NotificationManager.cancelReminder(for: target)
        }

        try? modelContext.save()
        dismiss()
    }
}

import SwiftUI
import SwiftData

struct EventDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(EventKitManager.self) private var eventKitManager
    @Bindable var event: Event

    @State private var isPresentingAccountPicker = false

    var body: some View {
        Form {
            Section("Details") {
                LabeledContent(
                    "Type",
                    value: event.type == .other ? (event.customTypeLabel ?? "Other") : event.type.rawValue
                )

                HStack {
                    Text("Account")
                    Spacer()
                    Text(event.account?.companyName ?? "Unassigned")
                        .foregroundStyle(.secondary)
                }

                DatePicker("Date", selection: $event.startDate)

                Button(event.account == nil ? "Assign to Account…" : "Change Account…") {
                    isPresentingAccountPicker = true
                }
            }

            if event.isRecurringCadence {
                Section {
                    Label("Part of a recurring cadence call series", systemImage: "repeat")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !event.isCompleted {
                Section {
                    Button("Mark Complete") { markComplete() }
                }
            } else {
                Section("Outcome") {
                    if let completedDate = event.completedDate {
                        LabeledContent("Completed", value: completedDate.formatted())
                    }
                    TextEditor(text: Binding(
                        get: { event.outcomeNotes ?? "" },
                        set: { event.outcomeNotes = $0 }
                    ))
                    .frame(minHeight: 100)
                }
            }

            Section {
                Button("Delete Event", role: .destructive) { deleteEvent() }
            }
        }
        .navigationTitle(event.title.isEmpty ? event.type.rawValue : event.title)
        .sheet(isPresented: $isPresentingAccountPicker) {
            AccountPickerView(selection: $event.account)
        }
        .onChange(of: event.startDate) { _, _ in
            if event.isSyncedToEventKit {
                eventKitManager.syncToAppleCalendar(event: event)
            }
        }
    }

    private func markComplete() {
        event.isCompleted = true
        event.completedDate = Date()
        NotificationManager.cancelReminders(for: event)
    }

    private func deleteEvent() {
        NotificationManager.cancelReminders(for: event)
        if event.isSyncedToEventKit {
            eventKitManager.removeFromAppleCalendar(event: event)
        }
        modelContext.delete(event)
    }
}

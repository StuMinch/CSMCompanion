import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cascadeSettingsQuery: [ReminderCascadeSettings]

    private var settings: ReminderCascadeSettings {
        if let existing = cascadeSettingsQuery.first {
            return existing
        }
        let created = ReminderCascadeSettings()
        modelContext.insert(created)
        return created
    }

    var body: some View {
        NavigationStack {
            Form {
                CascadeEditorSection(title: "Renewal", days: bindingFor(\.renewalDaysBefore))
                CascadeEditorSection(title: "EBR", days: bindingFor(\.ebrDaysBefore))
                CascadeEditorSection(title: "QBR", days: bindingFor(\.qbrDaysBefore))
                CascadeEditorSection(title: "Cadence Call", days: bindingFor(\.cadenceCallDaysBefore))

                Section {
                    Text("Changing these only affects reminders scheduled after this point. Reminders already scheduled for existing events keep their original schedule until that event's date is edited.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Reminder Settings")
        }
    }

    private func bindingFor(_ keyPath: ReferenceWritableKeyPath<ReminderCascadeSettings, [Int]>) -> Binding<[Int]> {
        Binding(
            get: { self.settings[keyPath: keyPath] },
            set: { newValue in
                self.settings[keyPath: keyPath] = newValue
                try? self.modelContext.save()
            }
        )
    }
}

private struct CascadeEditorSection: View {
    let title: String
    @Binding var days: [Int]
    @State private var newDayText = ""

    var body: some View {
        Section(title) {
            ForEach(days.sorted(by: >), id: \.self) { day in
                HStack {
                    Text("\(day) days before")
                    Spacer()
                    Button(role: .destructive) {
                        days.removeAll { $0 == day }
                    } label: {
                        Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                    }
                }
            }

            HStack {
                TextField("Add days before (e.g. 45)", text: $newDayText)
                    .keyboardType(.numberPad)
                Button("Add") {
                    if let value = Int(newDayText), value > 0, !days.contains(value) {
                        days.append(value)
                        newDayText = ""
                    }
                }
            }
        }
    }
}

import SwiftUI

struct TaskRow: View {
    @Bindable var task: CSMTask

    var body: some View {
        HStack {
            Button {
                toggleComplete()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                if let account = task.account {
                    Text(account.companyName).font(.caption).foregroundStyle(.secondary)
                }

                if let due = task.dueDate {
                    Text(due, format: .dateTime.month().day().hour().minute())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }

    private func toggleComplete() {
        task.isCompleted.toggle()
        task.completedDate = task.isCompleted ? Date() : nil

        if task.isCompleted {
            NotificationManager.cancelReminder(for: task)
        } else if task.dueDate != nil {
            NotificationManager.scheduleReminder(for: task)
        }
    }
}

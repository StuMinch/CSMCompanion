import SwiftUI

struct DayScheduleView: View {
    let date: Date
    let events: [Event]

    var body: some View {
        List {
            Section(date.formatted(date: .complete, time: .omitted)) {
                if events.isEmpty {
                    Text("No events").foregroundStyle(.secondary)
                } else {
                    ForEach(events.sorted { $0.startDate < $1.startDate }) { event in
                        NavigationLink(value: event) {
                            EventRow(event: event)
                        }
                    }
                }
            }
        }
        .navigationDestination(for: Event.self) { event in
            EventDetailView(event: event)
        }
    }
}

struct EventRow: View {
    let event: Event

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(event.type.color)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title.isEmpty ? event.type.rawValue : event.title)
                    .font(.headline)
                HStack(spacing: 4) {
                    Text(event.startDate, style: .time)
                    if event.isRecurringCadence {
                        Image(systemName: "repeat")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if event.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }
}

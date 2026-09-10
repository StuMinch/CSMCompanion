import SwiftUI

/// Backs both the Week (7 days) and 3-Day views — a simple, easy-to-restyle
/// scrolling list of day sections rather than an hour-by-hour grid.
struct MultiDayScheduleView: View {
    let startDate: Date
    let numberOfDays: Int
    let allEvents: [Event]

    private var days: [Date] {
        (0..<numberOfDays).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: startDate)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(days, id: \.self) { day in
                    Section {
                        let dayEvents = allEvents
                            .filter { Calendar.current.isDate($0.startDate, inSameDayAs: day) }
                            .sorted { $0.startDate < $1.startDate }

                        if dayEvents.isEmpty {
                            Text("No events")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                        } else {
                            ForEach(dayEvents) { event in
                                NavigationLink(value: event) {
                                    EventRow(event: event)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                            }
                        }
                    } header: {
                        Text(day.formatted(.dateTime.weekday(.wide).month().day()))
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 12)
                    }
                }
            }
        }
        .navigationDestination(for: Event.self) { event in
            EventDetailView(event: event)
        }
    }
}

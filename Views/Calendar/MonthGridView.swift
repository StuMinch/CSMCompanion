import SwiftUI

/// A deliberately simple month grid — a 7-column layout with a dot marking
/// days that have events, and the selected day's schedule shown underneath.
/// Not a full calendar-kit replacement; easy to swap out later.
struct MonthGridView: View {
    @Binding var referenceDate: Date
    let events: [Event]

    @State private var selectedDay: Date?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    private var gridDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: referenceDate) else { return [] }
        let firstOfMonth = monthInterval.start
        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        var leading = weekdayOfFirst - calendar.firstWeekday
        if leading < 0 { leading += 7 }

        let daysInMonth = calendar.range(of: .day, in: .month, for: referenceDate)?.count ?? 30

        var result: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: offset, to: firstOfMonth) {
                result.append(date)
            }
        }
        while result.count % 7 != 0 {
            result.append(nil)
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { shiftMonth(by: -1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(referenceDate.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                Spacer()
                Button { shiftMonth(by: 1) } label: { Image(systemName: "chevron.right") }
            }
            .padding()

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(gridDays.enumerated()), id: \.offset) { _, day in
                    if let day {
                        DayCell(
                            day: day,
                            eventCount: events.filter { calendar.isDate($0.startDate, inSameDayAs: day) }.count,
                            isSelected: selectedDay.map { calendar.isDate($0, inSameDayAs: day) } ?? false
                        )
                        .onTapGesture { selectedDay = day }
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
            .padding(.horizontal)

            Divider().padding(.top, 8)

            if let selectedDay {
                DayScheduleView(
                    date: selectedDay,
                    events: events.filter { calendar.isDate($0.startDate, inSameDayAs: selectedDay) }
                )
            } else {
                Spacer()
                Text("Tap a day to see its events")
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .onAppear {
            if selectedDay == nil { selectedDay = referenceDate }
        }
    }

    private func shiftMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: referenceDate) {
            referenceDate = newDate
            selectedDay = nil
        }
    }
}

private struct DayCell: View {
    let day: Date
    let eventCount: Int
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: day))")
                .font(.subheadline)
                .frame(width: 32, height: 32)
                .background(isSelected ? Color.accentColor : Color.clear)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Circle())

            Circle()
                .fill(eventCount > 0 ? Color.accentColor : Color.clear)
                .frame(width: 5, height: 5)
        }
        .frame(height: 44)
    }
}

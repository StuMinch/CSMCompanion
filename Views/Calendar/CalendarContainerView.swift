import SwiftUI
import SwiftData

enum CalendarViewMode: String, CaseIterable, Identifiable {
    case day = "Day", threeDay = "3-Day", week = "Week", month = "Month"
    var id: String { rawValue }
}

struct CalendarContainerView: View {
    @Environment(EventKitManager.self) private var eventKitManager
    @Query private var events: [Event]
    @Query private var ignoredEvents: [IgnoredCalendarEvent]

    @State private var viewMode: CalendarViewMode = .month
    @State private var referenceDate = Date()
    @State private var isPresentingAddEvent = false
    @State private var isPresentingUnlinkedReview = false
    @State private var unlinkedCount = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $viewMode) {
                    ForEach(CalendarViewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                Group {
                    switch viewMode {
                    case .day:
                        DayScheduleView(date: referenceDate, events: eventsOn(referenceDate))
                    case .threeDay:
                        MultiDayScheduleView(startDate: referenceDate, numberOfDays: 3, allEvents: events)
                    case .week:
                        MultiDayScheduleView(startDate: referenceDate.startOfWeek, numberOfDays: 7, allEvents: events)
                    case .month:
                        MonthGridView(referenceDate: $referenceDate, events: events)
                    }
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Today") { referenceDate = Date() }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    if unlinkedCount > 0 {
                        Button {
                            isPresentingUnlinkedReview = true
                        } label: {
                            Label("\(unlinkedCount) to link", systemImage: "questionmark.circle")
                        }
                    }
                    Button {
                        isPresentingAddEvent = true
                    } label: {
                        Label("Add Event", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddEvent) {
                AddEventView(defaultDate: referenceDate)
            }
            .sheet(
                isPresented: $isPresentingUnlinkedReview,
                onDismiss: { Task { await refreshUnlinkedCount() } }
            ) {
                UnlinkedEventsReviewView()
            }
            .task { await refreshUnlinkedCount() }
        }
    }

    private func eventsOn(_ date: Date) -> [Event] {
        events.filter { Calendar.current.isDate($0.startDate, inSameDayAs: date) }
    }

    private func refreshUnlinkedCount() async {
        guard eventKitManager.isAuthorized else { unlinkedCount = 0; return }
        let known = Set(events.compactMap(\.eventKitIdentifier))
            .union(ignoredEvents.map(\.eventKitIdentifier))
        let start = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let end = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        unlinkedCount = eventKitManager.fetchUnlinkedAppleCalendarEvents(
            from: start, to: end, knownEventKitIdentifiers: known
        ).count
    }
}

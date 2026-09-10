import SwiftUI
import SwiftData

@main
struct CSMCompanionApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                Account.self,
                Event.self,
                CSMTask.self,
                NewsItem.self,
                ReminderCascadeSettings.self,
                IgnoredCalendarEvent.self
            ])
            let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create CloudKit-backed ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

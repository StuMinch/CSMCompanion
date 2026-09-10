import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            AccountsListView()
                .tabItem { Label("Accounts", systemImage: "building.2") }

            NewsFeedView()
                .tabItem { Label("News", systemImage: "newspaper") }

            CalendarContainerView()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            TasksListView()
                .tabItem { Label("Tasks", systemImage: "checklist") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

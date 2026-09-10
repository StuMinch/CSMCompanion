import SwiftUI
import SwiftData

struct TasksListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<CSMTask> { !$0.isCleared }, sort: \CSMTask.createdDate, order: .reverse)
    private var tasks: [CSMTask]

    @State private var isPresentingAddTask = false

    private var openTasks: [CSMTask] { tasks.filter { !$0.isCompleted } }
    private var completedTasks: [CSMTask] { tasks.filter(\.isCompleted) }

    var body: some View {
        NavigationStack {
            List {
                Section("Open") {
                    if openTasks.isEmpty {
                        Text("Nothing to do").foregroundStyle(.secondary)
                    } else {
                        ForEach(openTasks) { task in
                            TaskRow(task: task)
                        }
                    }
                }

                if !completedTasks.isEmpty {
                    Section {
                        ForEach(completedTasks) { task in
                            TaskRow(task: task)
                        }
                    } header: {
                        Text("Completed")
                    } footer: {
                        Button("Clear Completed Tasks") {
                            clearCompleted()
                        }
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingAddTask = true
                    } label: {
                        Label("Add Task", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddTask) {
                AddEditTaskView(task: nil)
            }
        }
    }

    private func clearCompleted() {
        for task in completedTasks {
            task.isCleared = true
        }
        try? modelContext.save()
    }
}

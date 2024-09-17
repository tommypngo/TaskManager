//
//  ContentView.swift
//  TaskManager
//
//  Created by Phuoc Ngo on 9/9/24.
//

import SwiftUI

struct Task: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var description: String
    var dueDate: Date
    var isCompleted: Bool
    var category: Category
    
    static func == (lhs: Task, rhs: Task) -> Bool {
        lhs.id == rhs.id
    }
}

struct Category: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var color: Color
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id
    }
}

class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var categories: [Category] = []
    
    init() {
        // Add some default categories
        categories = [
            Category(name: "Work", color: .blue),
            Category(name: "Personal", color: .green),
            Category(name: "Errands", color: .orange)
        ]
    }
    
    func addTask(_ task: Task) {
        tasks.append(task)
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        }
    }
    
    func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }
    
    func addCategory(_ category: Category) {
        categories.append(category)
    }
}

struct ContentView: View {
    @StateObject private var taskManager = TaskManager()
    
    var body: some View {
        TabView {
            TaskListView()
                .tabItem {
                    Label("Tasks", systemImage: "list.bullet")
                }
            
            CategoriesView()
                .tabItem {
                    Label("Categories", systemImage: "folder")
                }
            
            StatisticsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar")
                }
        }
        .environmentObject(taskManager)
        .accentColor(.purple) // Set a custom accent color for the app
    }
}

struct TaskListView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var showingAddTask = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Add a gradient background
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                List {
                    ForEach(taskManager.tasks) { task in
                        NavigationLink(destination: TaskDetailView(task: task)) {
                            TaskRowView(task: task)
                        }
                        .listRowBackground(task.category.color.opacity(0.1))
                    }
                    .onDelete(perform: taskManager.deleteTask)
                }
                //.listStyle(.automatic)
            }
            .navigationTitle("My Tasks")
            .toolbar {
                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.purple)
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
        }
    }
}

struct TaskRowView: View {
    let task: Task
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(task.category.color)
                Text(task.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(task.dueDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.blue)
                Text(task.category.name)
                    .font(.caption2)
                    .padding(4)
                    .background(task.category.color.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddTaskView: View {
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.presentationMode) var presentationMode
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    @State private var selectedCategory: Category?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details").foregroundColor(.purple)) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }
                
                Section(header: Text("Category").foregroundColor(.purple)) {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(taskManager.categories) { category in
                            Text(category.name)
                                .tag(category as Category?)
                                .foregroundColor(category.color)
                        }
                    }
                }
            }
            .navigationTitle("Add New Task")
            .toolbar {
                Button("Save") {
                    if let category = selectedCategory {
                        let newTask = Task(title: title, description: description, dueDate: dueDate, isCompleted: false, category: category)
                        taskManager.addTask(newTask)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .disabled(selectedCategory == nil || title.isEmpty)
            }
        }
    }
}

struct TaskDetailView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var task: Task
    
    init(task: Task) {
        _task = State(initialValue: task)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Task Details").foregroundColor(task.category.color)) {
                TextField("Title", text: $task.title)
                TextField("Description", text: $task.description)
                DatePicker("Due Date", selection: $task.dueDate, displayedComponents: .date)
            }
            
            Section(header: Text("Category").foregroundColor(task.category.color)) {
                Text(task.category.name)
                    .foregroundColor(task.category.color)
            }
            
            Section {
                Toggle("Completed", isOn: $task.isCompleted)
                    .toggleStyle(SwitchToggleStyle(tint: task.category.color))
            }
        }
        .navigationTitle("Task Details")
        .onDisappear {
            taskManager.updateTask(task)
        }
    }
}

struct CategoriesView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var showingAddCategory = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(taskManager.categories) { category in
                    HStack {
                        Text(category.name)
                            .foregroundColor(category.color)
                        Spacer()
                        Circle()
                            .fill(category.color)
                            .frame(width: 20, height: 20)
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(category.color.opacity(0.1))
                }
            }
            //.listStyle(InsetGroupedListStyle())
            .navigationTitle("Categories")
            .toolbar {
                Button(action: { showingAddCategory = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.purple)
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView()
            }
        }
    }
}

struct AddCategoryView: View {
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var color = Color.blue
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Category Name", text: $name)
                ColorPicker("Category Color", selection: $color)
            }
            .navigationTitle("Add Category")
            .toolbar {
                Button("Save") {
                    let newCategory = Category(name: name, color: color)
                    taskManager.addCategory(newCategory)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(name.isEmpty)
            }
        }
    }
}

struct StatisticsView: View {
    @EnvironmentObject var taskManager: TaskManager
    
    var completedTasksCount: Int {
        taskManager.tasks.filter { $0.isCompleted }.count
    }
    
    var completionRate: Double {
        guard !taskManager.tasks.isEmpty else { return 0 }
        return Double(completedTasksCount) / Double(taskManager.tasks.count)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Add a gradient background
                LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.2), Color.blue.opacity(0.2)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                List {
                    Section(header: Text("Task Statistics").foregroundColor(.purple)) {
                        StatRow(title: "Total Tasks", value: "\(taskManager.tasks.count)", color: .blue)
                        StatRow(title: "Completed Tasks", value: "\(completedTasksCount)", color: .green)
                        StatRow(title: "Completion Rate", value: String(format: "%.1f%%", completionRate * 100), color: .orange)
                    }
                    
                    Section(header: Text("Task Distribution").foregroundColor(.purple)) {
                        ForEach(taskManager.categories) { category in
                            let count = taskManager.tasks.filter { $0.category.id == category.id }.count
                            StatRow(title: category.name, value: "\(count)", color: category.color)
                        }
                    }
                }
                //.listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Statistics")
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}


#Preview {
    ContentView()
}

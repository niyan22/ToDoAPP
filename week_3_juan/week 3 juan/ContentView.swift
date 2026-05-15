import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TodoViewModel()
    @FocusState private var isInputFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var showAddSheet = false

    // Modern color palette
    private let primaryGradient = LinearGradient(
        colors: [Color(hex: "667EEA"), Color(hex: "764BA2")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let secondaryGradient = LinearGradient(
        colors: [Color(hex: "F093FB"), Color(hex: "F5576C")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let accentColor = Color(hex: "4ECDC4")
    private let backgroundColor = Color(hex: "F8F9FA")

    var body: some View {
        NavigationView {
            ZStack {
                // Modern background with subtle pattern
                backgroundColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with progress
                    headerView

                    // Main content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Quick stats cards
                            statsCardsView

                            // Add new todo card
                            addTodoCardView

                            // Filter and search
                            filterSearchView

                            // Todo list
                            todoListView
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100) // Space for FAB
                    }
                }

                // Floating Action Button
                floatingActionButton
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
            .sheet(isPresented: $showAddSheet) {
                AddTodoSheet(viewModel: viewModel)
            }
            .sheet(item: $viewModel.editingTodo) { todo in
                EditTodoSheet(todo: todo, viewModel: viewModel)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        ZStack {
            primaryGradient
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Tasks")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Stay organized and productive")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))

                        Text("Storage: \(viewModel.storageMode)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 4)
                    }
                    Spacer()

                    // Profile avatar placeholder
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        )
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                // Progress card
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 8)
                            .frame(width: 80, height: 80)

                        Circle()
                            .trim(from: 0, to: viewModel.progress)
                            .stroke(Color.white, lineWidth: 8)
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 2) {
                            Text("\(Int(viewModel.progress * 100))%")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Done")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.completedCount) of \(viewModel.todos.count)")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)

                        Text("tasks completed")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(height: 200)
    }

    // MARK: - Stats Cards View
    private var statsCardsView: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Today",
                value: "\(viewModel.todayTodos.count)",
                icon: "calendar",
                gradient: primaryGradient
            )

            StatCard(
                title: "Pending",
                value: "\(viewModel.pendingTodos.count)",
                icon: "clock",
                gradient: secondaryGradient
            )

            StatCard(
                title: "High Priority",
                value: "\(viewModel.highPriorityTodos.count)",
                icon: "exclamationmark.triangle",
                gradient: LinearGradient(colors: [Color.red, Color.orange], startPoint: .top, endPoint: .bottom)
            )
        }
        .padding(.top, 20)
    }

    // MARK: - Add Todo Card View
    private var addTodoCardView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add New Task")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .frame(height: 50)

                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(accentColor)
                            .font(.system(size: 20))

                        TextField("What needs to be done?", text: $viewModel.newTodoTitle)
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.primary)
                            .focused($isInputFocused)

                        Spacer()

                        if !viewModel.newTodoTitle.isEmpty {
                            Button(action: { viewModel.addTodo(); isInputFocused = false }) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundColor(accentColor)
                                    .font(.system(size: 24))
                            }
                            .transition(.scale)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }

            // Quick priority selector
            HStack(spacing: 8) {
                ForEach(TodoItem.Priority.allCases, id: \.self) { priority in
                    PriorityButton(
                        priority: priority,
                        isSelected: viewModel.newTodoPriority == priority,
                        action: { viewModel.newTodoPriority = priority }
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
    }

    // MARK: - Filter Search View
    private var filterSearchView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filter & Search")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)

            // Filter tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TodoViewModel.Filter.allCases, id: \.self) { filter in
                        FilterTab(
                            title: filter.rawValue,
                            isSelected: viewModel.filter == filter,
                            action: { viewModel.filter = filter }
                        )
                    }
                }
            }

            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))

                TextField("Search tasks...", text: $viewModel.searchText)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.primary)

                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }

    // MARK: - Todo List View
    private var todoListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tasks")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                Text("\(viewModel.filteredTodos.count) items")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }

            if viewModel.filteredTodos.isEmpty {
                EmptyStateView(
                    icon: viewModel.searchText.isEmpty ? "checklist" : "magnifyingglass",
                    title: viewModel.searchText.isEmpty ? "No tasks yet" : "No matching tasks",
                    message: viewModel.searchText.isEmpty ?
                        "Add your first task to get started!" :
                        "Try adjusting your search or filter criteria."
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredTodos) { todo in
                        TodoRowView(
                            todo: todo,
                            toggleCompletion: { viewModel.toggleCompletion(todo) },
                            onEdit: { viewModel.editingTodo = todo },
                            onDelete: { viewModel.deleteTodo(todo) }
                        )
                        .transition(.slide)
                    }
                }
            }
        }
    }

    // MARK: - Floating Action Button
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { showAddSheet = true }) {
                    ZStack {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 60, height: 60)
                            .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)

                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: LinearGradient

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 16))
            }

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct PriorityButton: View {
    let priority: TodoItem.Priority
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(priority.rawValue)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : priority.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? priority.color : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(priority.color, lineWidth: isSelected ? 0 : 1)
                        )
                )
        }
    }
}

struct FilterTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)

            Text(message)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Add Todo Sheet
struct AddTodoSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: TodoViewModel
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task title", text: $viewModel.newTodoTitle)
                        .focused($isTitleFocused)
                        .onAppear { isTitleFocused = true }

                    Picker("Priority", selection: $viewModel.newTodoPriority) {
                        ForEach(TodoItem.Priority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }

                    DatePicker("Due Date", selection: Binding(
                        get: { viewModel.newTodoDueDate ?? Date() },
                        set: { viewModel.newTodoDueDate = $0 }
                    ), displayedComponents: .date)
                }
            }
            .navigationTitle("Add New Task")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addTodo()
                        dismiss()
                    }
                    .disabled(viewModel.newTodoTitle.isEmpty)
                }
            }
        }
    }
}

// MARK: - Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Computed Properties (keeping original ones for compatibility)
extension ContentView {
    private var emptyDescription: String {
        switch viewModel.filter {
        case .all: return "Tambahkan tugas baru atau ubah filter"
        case .active: return "Tidak ada tugas aktif"
        case .completed: return "Tidak ada tugas selesai"
        }
    }

    private var inputBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.95)
    }

    private var searchBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.95)
    }
}

// MARK: - Progress Ring Component
struct ProgressRing: View {
    let progress: Double
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
            Text("\(Int(progress * 100))%")
                .font(.caption2.bold())
        }
    }
}

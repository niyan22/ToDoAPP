import SwiftUI

class TodoViewModel: ObservableObject {
    @Published private(set) var todos: [TodoItem] = []
    @Published var storageMode: String = "Firebase"
    @Published var newTodoTitle = ""
    @Published var newTodoDueDate: Date? = nil
    @Published var newTodoPriority: TodoItem.Priority = .medium
    @Published var filter: Filter = .all {
        didSet { saveFilterToUserDefaults() }
    }
    @Published var errorMessage: String?
    @Published var editingTodo: TodoItem? = nil
    @Published var searchText = ""

    private let repository = TodoRepository.shared

    enum Filter: String, CaseIterable {
        case all = "Semua", active = "Aktif", completed = "Selesai"
    }

    init() {
        loadTodos()
        if let savedFilterRaw = UserDefaults.standard.string(forKey: "selectedFilter"),
           let savedFilter = Filter(rawValue: savedFilterRaw) {
            filter = savedFilter
        }
    }

    func loadTodos() {
        repository.getAllTodos { [weak self] loadedTodos in
            self?.todos = loadedTodos
            self?.storageMode = self?.repository.storageMode ?? "Unknown"
        }
    }

    var filteredTodos: [TodoItem] {
        let filteredByStatus: [TodoItem]
        switch filter {
        case .all: filteredByStatus = todos
        case .active: filteredByStatus = todos.filter { !$0.isCompleted }
        case .completed: filteredByStatus = todos.filter { $0.isCompleted }
        }
        if searchText.isEmpty { return filteredByStatus }
        return filteredByStatus.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var completedCount: Int {
        todos.filter(\.isCompleted).count
    }

    var todayTodos: [TodoItem] {
        todos.filter {
            guard let dueDate = $0.dueDate else { return false }
            return Calendar.current.isDateInToday(dueDate)
        }
    }

    var pendingTodos: [TodoItem] {
        todos.filter { !$0.isCompleted }
    }

    var highPriorityTodos: [TodoItem] {
        todos.filter { $0.priority == .high }
    }

    var progress: Double {
        guard !todos.isEmpty else { return 0 }
        return Double(todos.filter(\.isCompleted).count) / Double(todos.count)
    }

    private func saveFilterToUserDefaults() {
        UserDefaults.standard.set(filter.rawValue, forKey: "selectedFilter")
    }

    func addTodo() {
        let trimmed = newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { errorMessage = "Judul tidak boleh kosong"; return }
        guard trimmed.count <= 150 else { errorMessage = "Maksimal 150 karakter"; return }

        let todo = TodoItem(title: trimmed, dueDate: newTodoDueDate, priority: newTodoPriority)
        repository.add(todo) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Gagal menambah: \(error.localizedDescription)"
                } else {
                    self?.errorMessage = nil
                    self?.newTodoTitle = ""
                    self?.newTodoDueDate = nil
                    self?.newTodoPriority = .medium
                    self?.loadTodos()
                }
            }
        }
    }

    func toggleCompletion(_ todo: TodoItem) {
        repository.toggleCompletion(id: todo.id) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Gagal update status: \(error.localizedDescription)"
                } else {
                    self?.loadTodos()
                }
            }
        }
    }

    func updateTodo(_ todo: TodoItem, title: String, dueDate: Date?, priority: TodoItem.Priority) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { errorMessage = "Judul tidak boleh kosong"; return }
        var updated = todo
        updated.title = trimmed
        updated.dueDate = dueDate
        updated.priority = priority
        repository.update(updated) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Gagal update: \(error.localizedDescription)"
                } else {
                    self?.editingTodo = nil
                    self?.loadTodos()
                }
            }
        }
    }

    func deleteTodo(_ todo: TodoItem) {
        repository.delete(id: todo.id) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Gagal hapus: \(error.localizedDescription)"
                } else {
                    self?.loadTodos()
                }
            }
        }
    }

    func deleteTodo(at offsets: IndexSet) {
        repository.delete(at: offsets) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Gagal hapus: \(error.localizedDescription)"
                } else {
                    self?.loadTodos()
                }
            }
        }
    }

    func clearCompleted() {
        repository.clearCompleted { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Gagal bersihkan: \(error.localizedDescription)"
                } else {
                    self?.loadTodos()
                }
            }
        }
    }
}

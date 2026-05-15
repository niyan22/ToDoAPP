import SwiftUI

@MainActor
class TodoViewModel: ObservableObject {
    @Published private(set) var todos: [TodoItem] = []
    @Published var newTodoTitle: String = ""
    @Published var newTodoDueDate: Date? = nil
    @Published var newTodoPriority: TodoItem.Priority = .medium

    @Published var filter: Filter = .all
    @Published var errorMessage: String?
    @Published var editingTodo: TodoItem? = nil

    var repository: TodoRepository

    enum Filter: String, CaseIterable {
        case all = "Semua"
        case active = "Aktif"
        case completed = "Selesai"
    }

    init(repository: TodoRepository = .shared) {
        self.repository = repository
        Task { await loadTodos() }
    }

    var filteredTodos: [TodoItem] {
        let base = todos

        let filtered: [TodoItem]
        switch filter {
        case .all:
            filtered = base
        case .active:
            filtered = base.filter { !$0.isCompleted }
        case .completed:
            filtered = base.filter { $0.isCompleted }
        }

        return filtered.sorted { lhs, rhs in
            switch (lhs.isCompleted, rhs.isCompleted) {
            case (true, false): return false
            case (false, true): return true
            default: return lhs.createdAt > rhs.createdAt
            }
        }
    }

    func loadTodos() async {
        let loaded = await repository.getAllTodos()
        todos = loaded
    }

    func addTodo() async {
        let trimmed = newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            errorMessage = "Judul tugas tidak boleh kosong"
            return
        }

        guard trimmed.count <= 150 else {
            errorMessage = "Judul tidak boleh lebih dari 150 karakter"
            return
        }

        let todo = TodoItem(title: trimmed, dueDate: newTodoDueDate, priority: newTodoPriority)

        do {
            try await repository.add(todo)
            errorMessage = nil
            newTodoTitle = ""
            newTodoDueDate = nil
            newTodoPriority = .medium
            await loadTodos()
        } catch {
            errorMessage = "Gagal menambah tugas: \(error.localizedDescription)"
        }
    }

    func toggleCompletion(_ todo: TodoItem) async {
        do {
            try await repository.toggleCompletion(id: todo.id)
            await loadTodos()
        } catch {
            errorMessage = "Gagal memperbarui status: \(error.localizedDescription)"
        }
    }

    func updateTodo(_ todo: TodoItem, title: String, dueDate: Date?, priority: TodoItem.Priority) async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Judul tugas tidak boleh kosong"
            return
        }

        var updated = todo
        updated.title = trimmedTitle
        updated.dueDate = dueDate
        updated.priority = priority

        do {
            try await repository.update(updated)
            errorMessage = nil
            editingTodo = nil
            await loadTodos()
        } catch {
            errorMessage = "Gagal memperbarui tugas: \(error.localizedDescription)"
        }
    }

    func deleteTodo(_ todo: TodoItem) async {
        do {
            try await repository.delete(id: todo.id)
            await loadTodos()
        } catch {
            errorMessage = "Gagal menghapus tugas: \(error.localizedDescription)"
        }
    }

    func deleteTodo(at offsets: IndexSet) async {
        do {
            try await repository.delete(at: offsets)
            await loadTodos()
        } catch {
            errorMessage = "Gagal menghapus item: \(error.localizedDescription)"
        }
    }

    func clearCompleted() async {
        do {
            try await repository.clearCompleted()
            await loadTodos()
        } catch {
            errorMessage = "Gagal membersihkan tugas selesai: \(error.localizedDescription)"
        }
    }
}

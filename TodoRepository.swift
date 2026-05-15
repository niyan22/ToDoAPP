import Foundation

actor TodoRepository {
    enum RepositoryError: Error {
        case invalidURL
        case saveFailure(Error)
        case loadFailure(Error)
        case notFound
    }

    static let shared = TodoRepository()

    private let fileName = "todos.json"
    private var todos: [TodoItem] = []

    init() {
        Task {
            await loadTodos()
        }
    }

    private var storageURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
    }

    func loadTodos() async {
        do {
            guard let url = storageURL else { throw RepositoryError.invalidURL }
            if !FileManager.default.fileExists(atPath: url.path) {
                todos = []
                return
            }
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            todos = try decoder.decode([TodoItem].self, from: data)
        } catch {
            print("[TodoRepository] load failure: \(error)")
            todos = []
        }
    }

    private func persist() throws {
        guard let url = storageURL else { throw RepositoryError.invalidURL }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            let encoded = try encoder.encode(todos)
            try encoded.write(to: url, options: [.atomicWrite])
        } catch {
            throw RepositoryError.saveFailure(error)
        }
    }

    func getAllTodos() async -> [TodoItem] {
        return todos.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted
            }
            if let ldue = lhs.dueDate, let rdue = rhs.dueDate {
                return ldue < rdue
            }
            return lhs.createdAt > rhs.createdAt
        }
    }

    func add(_ newTodo: TodoItem) async throws {
        guard !newTodo.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RepositoryError.saveFailure(NSError(domain: "TodoRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Judul tidak boleh kosong"]))
        }
        todos.append(newTodo)
        try persist()
    }

    func update(_ updatedTodo: TodoItem) async throws {
        guard let index = todos.firstIndex(where: { $0.id == updatedTodo.id }) else {
            throw RepositoryError.notFound
        }
        todos[index] = updatedTodo
        try persist()
    }

    func toggleCompletion(id: UUID) async throws {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { throw RepositoryError.notFound }
        todos[index].isCompleted.toggle()
        try persist()
    }

    func delete(id: UUID) async throws {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { throw RepositoryError.notFound }
        todos.remove(at: index)
        try persist()
    }

    func delete(at offsets: IndexSet) async throws {
        let sortedOffsets = offsets.sorted(by: >)
        for offset in sortedOffsets {
            guard todos.indices.contains(offset) else { continue }
            todos.remove(at: offset)
        }
        try persist()
    }

    func clearCompleted() async throws {
        todos.removeAll(where: { $0.isCompleted })
        try persist()
    }
}

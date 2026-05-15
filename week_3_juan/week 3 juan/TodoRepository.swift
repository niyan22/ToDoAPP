import Foundation
import FirebaseFirestore

class TodoRepository {
    enum RepositoryError: Error {
        case invalidURL, saveFailure(Error), loadFailure(Error), notFound, firestoreError(String)
    }

    static let shared = TodoRepository()

    private let fileName = "todos.json"
    private var todos: [TodoItem] = []
    private let db = Firestore.firestore()
    private var useFirebase = true // Toggle to use Firebase (set to false for local storage only)

    var storageMode: String {
        useFirebase ? "Firebase" : "Local"
    }

    var isUsingFirebase: Bool {
        useFirebase
    }

    // Firebase collection paths
    private let collectionName = "todos"

    private var storageURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?.appendingPathComponent(fileName)
    }

    init() {
        if useFirebase {
            print("TodoRepository: starting with Firebase mode")
            loadTodos()
            setupFirestoreListener()
        } else {
            print("TodoRepository: starting in Local mode")
            loadTodos()
        }
    }

    // MARK: - Firebase Setup
    private func setupFirestoreListener() {
        print("TodoRepository: setting up Firestore listener")
        db.collection(collectionName)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("TodoRepository: Firestore listener error: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }
                self?.todos = documents.compactMap { doc in
                    self?.todoItem(from: doc)
                }.sorted { lhs, rhs in
                    if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted }
                    if let ldue = lhs.dueDate, let rdue = rhs.dueDate { return ldue < rdue }
                    return lhs.createdAt > rhs.createdAt
                }
                print("TodoRepository: loaded \(self?.todos.count ?? 0) todos from Firestore")
            }
    }

    // Cold data saat pertama kali
    private func getColdData() -> [TodoItem] {
        return [
            TodoItem(title: "Belajar SwiftUI", priority: .high),
            TodoItem(title: "Beli groceries", dueDate: Date().addingTimeInterval(86400), priority: .medium),
            TodoItem(title: "Olahraga pagi", isCompleted: true, priority: .low),
            TodoItem(title: "Baca buku", priority: .medium)
        ]
    }

    private func loadTodos() {
        if useFirebase {
            loadTodosFromFirebase()
        } else {
            loadTodosFromLocal()
        }
    }
    
    private func loadTodosFromLocal() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            do {
                guard let url = self.storageURL else { throw RepositoryError.invalidURL }
                if !FileManager.default.fileExists(atPath: url.path) {
                    self.todos = self.getColdData()
                    try? self.persist()
                    return
                }
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                self.todos = try decoder.decode([TodoItem].self, from: data)
            } catch {
                print("Load error: \(error)")
                self.todos = self.getColdData()
            }
        }
    }
    
    private func loadTodosFromFirebase() {
        print("TodoRepository: loading todos from Firestore")
        db.collection(collectionName).getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("TodoRepository: Firebase load error: \(error.localizedDescription)")
                self?.loadTodosFromLocal()
                return
            }

            guard let documents = snapshot?.documents else {
                self?.todos = self?.getColdData() ?? []
                return
            }

            self?.todos = documents.compactMap { doc in
                self?.todoItem(from: doc)
            }.sorted { lhs, rhs in
                if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted }
                if let ldue = lhs.dueDate, let rdue = rhs.dueDate { return ldue < rdue }
                return lhs.createdAt > rhs.createdAt
            }
            print("TodoRepository: loaded \(self?.todos.count ?? 0) todos from Firestore")
        }
    }

    private func todoItem(from document: QueryDocumentSnapshot) -> TodoItem? {
        let data = document.data()
        guard let title = data["title"] as? String else { return nil }
        let isCompleted = data["isCompleted"] as? Bool ?? false
        let priority = TodoItem.Priority(rawValue: data["priority"] as? String ?? "") ?? .medium
        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else if let date = data["createdAt"] as? Date {
            createdAt = date
        } else {
            createdAt = Date()
        }
        let dueDate: Date?
        if let timestamp = data["dueDate"] as? Timestamp {
            dueDate = timestamp.dateValue()
        } else if let date = data["dueDate"] as? Date {
            dueDate = date
        } else {
            dueDate = nil
        }
        let id = (data["id"] as? String).flatMap(UUID.init(uuidString:)) ?? UUID()
        return TodoItem(id: id, title: title, isCompleted: isCompleted, dueDate: dueDate, priority: priority, createdAt: createdAt)
    }

    private func firestoreData(from todo: TodoItem) -> [String: Any] {
        var data: [String: Any] = [
            "id": todo.id.uuidString,
            "title": todo.title,
            "isCompleted": todo.isCompleted,
            "priority": todo.priority.rawValue,
            "createdAt": todo.createdAt
        ]
        if let dueDate = todo.dueDate {
            data["dueDate"] = dueDate
        }
        return data
    }

    private func persist() throws {
        guard let url = storageURL else { throw RepositoryError.invalidURL }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let encoded = try encoder.encode(todos)
        try encoded.write(to: url, options: .atomicWrite)
    }

    // MARK: - Public methods (completion handlers)
    func getAllTodos(completion: @escaping ([TodoItem]) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            let sorted = self?.todos.sorted { lhs, rhs in
                if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted }
                if let ldue = lhs.dueDate, let rdue = rhs.dueDate { return ldue < rdue }
                return lhs.createdAt > rhs.createdAt
            } ?? []
            DispatchQueue.main.async { completion(sorted) }
        }
    }

    func add(_ newTodo: TodoItem, completion: @escaping (Error?) -> Void) {
        let trimmed = newTodo.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion(RepositoryError.saveFailure(NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "Judul tidak boleh kosong"])))
            return
        }
        
        if useFirebase {
            addToFirebase(newTodo, completion: completion)
        } else {
            addToLocal(newTodo, completion: completion)
        }
    }
    
    private func addToLocal(_ newTodo: TodoItem, completion: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            self.todos.append(newTodo)
            do {
                try self.persist()
                DispatchQueue.main.async { completion(nil) }
            } catch {
                DispatchQueue.main.async { completion(error) }
            }
        }
    }
    
    private func addToFirebase(_ newTodo: TodoItem, completion: @escaping (Error?) -> Void) {
        print("TodoRepository: addToFirebase title=\(newTodo.title)")
        let collection = db.collection(collectionName)
        let docRef = collection.document(newTodo.id.uuidString)
        let data: [String: Any] = firestoreData(from: newTodo)
        docRef.setData(data) { error in
            if let error = error {
                print("TodoRepository: addToFirebase error=\(error.localizedDescription)")
            } else {
                print("TodoRepository: addToFirebase success id=\(newTodo.id.uuidString)")
            }
            DispatchQueue.main.async { completion(error) }
        }
    }

    func update(_ updatedTodo: TodoItem, completion: @escaping (Error?) -> Void) {
        if useFirebase {
            updateInFirebase(updatedTodo, completion: completion)
        } else {
            updateInLocal(updatedTodo, completion: completion)
        }
    }
    
    private func updateInLocal(_ updatedTodo: TodoItem, completion: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            guard let index = self.todos.firstIndex(where: { $0.id == updatedTodo.id }) else {
                DispatchQueue.main.async { completion(RepositoryError.notFound) }
                return
            }
            self.todos[index] = updatedTodo
            do {
                try self.persist()
                DispatchQueue.main.async { completion(nil) }
            } catch {
                DispatchQueue.main.async { completion(error) }
            }
        }
    }
    
    private func updateInFirebase(_ updatedTodo: TodoItem, completion: @escaping (Error?) -> Void) {
        let data = firestoreData(from: updatedTodo)
        db.collection(collectionName).document(updatedTodo.id.uuidString).setData(data, merge: true) { error in
            DispatchQueue.main.async { completion(error) }
        }
    }

    func toggleCompletion(id: UUID, completion: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            guard let index = self.todos.firstIndex(where: { $0.id == id }) else {
                DispatchQueue.main.async { completion(RepositoryError.notFound) }
                return
            }
            self.todos[index].isCompleted.toggle()
            
            if self.useFirebase {
                DispatchQueue.main.async {
                    self.updateInFirebase(self.todos[index], completion: completion)
                }
            } else {
                do {
                    try self.persist()
                    DispatchQueue.main.async { completion(nil) }
                } catch {
                    DispatchQueue.main.async { completion(error) }
                }
            }
        }
    }

    func delete(id: UUID, completion: @escaping (Error?) -> Void) {
        if useFirebase {
            deleteFromFirebase(id: id, completion: completion)
        } else {
            deleteFromLocal(id: id, completion: completion)
        }
    }
    
    private func deleteFromLocal(id: UUID, completion: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            guard let index = self.todos.firstIndex(where: { $0.id == id }) else {
                DispatchQueue.main.async { completion(RepositoryError.notFound) }
                return
            }
            self.todos.remove(at: index)
            do {
                try self.persist()
                DispatchQueue.main.async { completion(nil) }
            } catch {
                DispatchQueue.main.async { completion(error) }
            }
        }
    }
    
    private func deleteFromFirebase(id: UUID, completion: @escaping (Error?) -> Void) {
        db.collection(collectionName).document(id.uuidString).delete { error in
            DispatchQueue.main.async { completion(error) }
        }
    }

    func delete(at offsets: IndexSet, completion: @escaping (Error?) -> Void) {
        if useFirebase {
            deleteFromFirebase(at: offsets, completion: completion)
        } else {
            deleteFromLocal(at: offsets, completion: completion)
        }
    }
    
    private func deleteFromLocal(at offsets: IndexSet, completion: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            let sortedOffsets = offsets.sorted(by: >)
            for offset in sortedOffsets {
                guard self.todos.indices.contains(offset) else { continue }
                self.todos.remove(at: offset)
            }
            do {
                try self.persist()
                DispatchQueue.main.async { completion(nil) }
            } catch {
                DispatchQueue.main.async { completion(error) }
            }
        }
    }
    
    private func deleteFromFirebase(at offsets: IndexSet, completion: @escaping (Error?) -> Void) {
        let batch = db.batch()
        var deleteCount = 0

        for offset in offsets {
            guard offset < todos.count else { continue }
            let doc = db.collection(collectionName).document(todos[offset].id.uuidString)
            batch.deleteDocument(doc)
            deleteCount += 1
        }

        guard deleteCount > 0 else {
            completion(nil)
            return
        }

        batch.commit { error in
            DispatchQueue.main.async { completion(error) }
        }
    }

    func clearCompleted(completion: @escaping (Error?) -> Void) {
        if useFirebase {
            clearCompletedInFirebase(completion: completion)
        } else {
            clearCompletedInLocal(completion: completion)
        }
    }
    
    private func clearCompletedInLocal(completion: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            self.todos.removeAll(where: \.isCompleted)
            do {
                try self.persist()
                DispatchQueue.main.async { completion(nil) }
            } catch {
                DispatchQueue.main.async { completion(error) }
            }
        }
    }
    
    private func clearCompletedInFirebase(completion: @escaping (Error?) -> Void) {
        db.collection(collectionName)
            .whereField("isCompleted", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    DispatchQueue.main.async { completion(error) }
                    return
                }

                let batch = self?.db.batch()
                documents.forEach { doc in
                    batch?.deleteDocument(doc.reference)
                }

                batch?.commit { error in
                    DispatchQueue.main.async { completion(error) }
                }
            }
    }
}


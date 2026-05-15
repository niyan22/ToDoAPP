import SwiftUI

struct EditTodoSheet: View {
    let todo: TodoItem
    @ObservedObject var viewModel: TodoViewModel

    @State private var editedTitle: String
    @State private var editedDueDate: Date?
    @State private var editedPriority: TodoItem.Priority

    @Environment(\.dismiss) private var dismiss

    init(todo: TodoItem, viewModel: TodoViewModel) {
        self.todo = todo
        self.viewModel = viewModel
        _editedTitle = State(initialValue: todo.title)
        _editedDueDate = State(initialValue: todo.dueDate)
        _editedPriority = State(initialValue: todo.priority)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Detail Tugas")) {
                    TextField("Judul tugas", text: $editedTitle)
                    Picker("Prioritas", selection: $editedPriority) {
                        ForEach(TodoItem.Priority.allCases, id: \ .self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    Toggle("Selesai", isOn: Binding(get: { todo.isCompleted }, set: { _ in }))
                        .disabled(true)
                }

                Section(header: Text("Tanggal Jatuh Tempo")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Jatuh Tempo")
                            .font(.caption)
                        DatePicker("", selection: Binding(
                            get: { editedDueDate ?? Date() },
                            set: { editedDueDate = $0 }
                        ), displayedComponents: .date)
                        
                        if editedDueDate != nil {
                            Button("Hapus tanggal") {
                                editedDueDate = nil
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Edit Tugas")
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        Task {
                            await viewModel.updateTodo(todo, title: editedTitle, dueDate: editedDueDate, priority: editedPriority)
                            dismiss()
                        }
                    }
                    .disabled(editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        Task {
                            await viewModel.updateTodo(todo, title: editedTitle, dueDate: editedDueDate, priority: editedPriority)
                            dismiss()
                        }
                    }
                    .disabled(editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            #endif
        }
    }
}

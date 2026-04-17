import SwiftUI

struct EditTodoSheet: View {
    let todo: TodoItem
    @ObservedObject var viewModel: TodoViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var editedTitle: String
    @State private var editedDueDate: Date?
    @State private var editedPriority: TodoItem.Priority

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
                Section {
                    TextField("Judul", text: $editedTitle)
                    Picker("Prioritas", selection: $editedPriority) {
                        ForEach(TodoItem.Priority.allCases, id: \.self) { p in
                            Label(p.rawValue, systemImage: "flag.fill").tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    Toggle("Selesai", isOn: .constant(todo.isCompleted))
                        .disabled(true)
                } header: {
                    Label("Detail Tugas", systemImage: "info.circle")
                }

                Section {
                    DatePicker("Jatuh tempo", selection: Binding(
                        get: { editedDueDate ?? Date() },
                        set: { editedDueDate = $0 }
                    ), displayedComponents: .date)
                    if editedDueDate != nil {
                        Button("Hapus tanggal", role: .destructive) {
                            editedDueDate = nil
                        }
                    }
                } header: {
                    Label("Tanggal", systemImage: "calendar")
                }
            }
            .navigationTitle("Edit Tugas")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        viewModel.updateTodo(todo, title: editedTitle, dueDate: editedDueDate, priority: editedPriority)
                        dismiss()
                    }
                    .disabled(editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

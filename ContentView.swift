import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TodoViewModel()
    @State private var isEditMode = false

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                newTodoInput

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }

                filterPicker

                taskList

                footerActions
            }
            .navigationTitle("ToDo App")
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            #endif
            .sheet(item: $viewModel.editingTodo) { todo in
                EditTodoSheet(todo: todo, viewModel: viewModel)
            }
            .task { await viewModel.loadTodos() }
        }
    }

    private var newTodoInput: some View {
        HStack {
            VStack(alignment: .leading) {
                TextField("Tugas baru...", text: $viewModel.newTodoTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                HStack {
                    VStack(alignment: .leading) {
                        Text("Jatuh Tempo")
                            .font(.caption)
                        DatePicker("", selection: Binding(
                            get: { viewModel.newTodoDueDate ?? Date() },
                            set: { viewModel.newTodoDueDate = $0 }
                        ), displayedComponents: .date)
                        #if os(macOS)
                        .datePickerStyle(.compact)
                        #else
                        .datePickerStyle(.compact)
                        #endif
                    }
                    Picker("Prioritas", selection: $viewModel.newTodoPriority) {
                        ForEach(TodoItem.Priority.allCases, id: \ .self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    #if os(iOS)
                    .pickerStyle(.segmented)
                    #endif
                }
            }

            Button("Tambah") {
                Task { await viewModel.addTodo() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $viewModel.filter) {
            ForEach(TodoViewModel.Filter.allCases, id: \ .self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    private var taskList: some View {
        List {
            ForEach(viewModel.filteredTodos) { todo in
                TodoRowView(todo: todo, toggleCompletion: {
                    Task { await viewModel.toggleCompletion(todo) }
                }, onEdit: {
                    viewModel.editingTodo = todo
                }, onDelete: {
                    Task { await viewModel.deleteTodo(todo) }
                })
                .listRowSeparator(.visible)
            }
            .onDelete { offsets in
                Task { await viewModel.deleteTodo(at: offsets) }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.bordered)
        #endif
        .overlay {
            if viewModel.filteredTodos.isEmpty {
                VStack(spacing: 8) {
                    Text("Tidak ada tugas")
                        .font(.title3)
                    Text(emptyMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }

    private var footerActions: some View {
        HStack {
            Text("Total: \(viewModel.filteredTodos.count)")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button("Bersihkan selesai") {
                Task { await viewModel.clearCompleted() }
            }
            .disabled(!viewModel.todos.contains { $0.isCompleted })
        }
        .padding(.horizontal)
    }

    private var emptyMessage: String {
        switch viewModel.filter {
        case .all: return "Tambahkan tugas baru atau ubah filter"
        case .active: return "Tidak ada tugas aktif"
        case .completed: return "Tidak ada tugas selesai"
        }
    }
}

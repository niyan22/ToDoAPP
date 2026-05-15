import SwiftUI

struct TodoRowView: View {
    let todo: TodoItem
    let toggleCompletion: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showingDeleteAlert = false

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation { toggleCompletion() }
            }) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(todo.priority.color.uiColor)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.body)
                    .strikethrough(todo.isCompleted, color: .secondary)
                    .foregroundColor(todo.isCompleted ? .gray : .primary)

                HStack(spacing: 8) {
                    Text(todo.priority.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(6)
                        .background(todo.priority.color.uiColor.opacity(0.2))
                        .cornerRadius(8)

                    if let dueDate = todo.dueDate {
                        Text("Deadline: \(dueDate, format: .dateTime.day().month().year())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Menu {
                Button("Edit", action: onEdit)
                Button("Hapus", role: .destructive, action: {
                    showingDeleteAlert = true
                })
            } label: {
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .padding(.vertical, 8)
            }
            .menuStyle(.bordered)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .alert("Hapus tugas?", isPresented: $showingDeleteAlert) {
            Button("Batal", role: .cancel) {}
            Button("Hapus", role: .destructive, action: onDelete)
        } message: {
            Text("Yakin ingin menghapus \"\(todo.title)\"?")
        }
        .padding(.vertical, 8)
    }
}


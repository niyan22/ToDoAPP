import SwiftUI

struct TodoRowView: View {
    let todo: TodoItem
    let toggleCompletion: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showingDeleteAlert = false
    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme

    private let accentColor = Color(hex: "4ECDC4")
    private let backgroundColor = Color(hex: "F8F9FA")

    var body: some View {
        HStack(spacing: 16) {
            // Completion Button with enhanced animation
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    toggleCompletion()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(todo.isCompleted ?
                              Color.green.opacity(0.2) :
                              Color.gray.opacity(0.1))
                        .frame(width: 32, height: 32)

                    if todo.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.green)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Circle()
                            .stroke(todo.priority.color.opacity(0.6), lineWidth: 2)
                            .frame(width: 24, height: 24)
                    }
                }
                .scaleEffect(todo.isCompleted ? 1.1 : 1.0)
            }
            .buttonStyle(.plain)

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(todo.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .strikethrough(todo.isCompleted, pattern: .solid, color: .secondary)
                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    // Priority Badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(todo.priority.color)
                            .frame(width: 8, height: 8)

                        Text(todo.priority.rawValue)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(todo.priority.color)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(todo.priority.color.opacity(0.1))
                    )

                    // Due Date
                    if let dueDate = todo.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))

                            Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(isOverdue(dueDate) ? .red : .secondary)
                    }
                }
            }

            Spacer()

            // Menu Button
            Menu {
                Button(action: onEdit) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                }
                Button(role: .destructive, action: { showingDeleteAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.secondary.opacity(0.1))
                    )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05),
                       radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .opacity(todo.isCompleted ? 0.7 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .animation(.easeInOut(duration: 0.3), value: todo.isCompleted)
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                onEdit()
            }
        }
        .alert("Delete Task?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("Are you sure you want to delete \"\(todo.title)\"?")
        }
    }

    private func isOverdue(_ date: Date) -> Bool {
        return date < Date() && !todo.isCompleted
    }
}

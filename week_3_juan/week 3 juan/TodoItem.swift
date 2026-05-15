import Foundation
import SwiftUI

struct TodoItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var isCompleted: Bool
    var dueDate: Date?
    var priority: Priority
    let createdAt: Date

    enum Priority: String, Codable, CaseIterable {
        case low = "Low", medium = "Medium", high = "High"

        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
    }

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false,
         dueDate: Date? = nil, priority: Priority = .medium, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.priority = priority
        self.createdAt = createdAt
    }
}

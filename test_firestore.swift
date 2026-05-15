import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

// Initialize Firebase
FirebaseApp.configure()

// Test data structure matching TodoItem
struct TestTodoItem {
    let id: String
    let title: String
    let isCompleted: Bool
    let dueDate: Date?
    let priority: String
    let createdAt: Date
    let userId: String

    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "title": title,
            "isCompleted": isCompleted,
            "priority": priority,
            "createdAt": createdAt,
            "userId": userId
        ]
        if let dueDate = dueDate {
            data["dueDate"] = dueDate
        }
        return data
    }
}

// Test function
func testFirestoreInsert() {
    print("🔥 Testing Firestore connection...")

    // Sign in anonymously first
    Auth.auth().signInAnonymously { authResult, error in
        if let error = error {
            print("❌ Anonymous auth failed: \(error.localizedDescription)")
            return
        }

        guard let userId = authResult?.user.uid else {
            print("❌ No user ID from auth")
            return
        }

        print("✅ Anonymous auth success, userId: \(userId)")

        let db = Firestore.firestore()

        // Create test data
        let testTodo = TestTodoItem(
            id: UUID().uuidString,
            title: "Test Task from Script",
            isCompleted: false,
            dueDate: Date().addingTimeInterval(86400), // Tomorrow
            priority: "high",
            createdAt: Date(),
            userId: userId
        )

        // Insert to Firestore
        let docRef = db.collection("todos").document(testTodo.id)

        docRef.setData(testTodo.toFirestoreData()) { error in
            if let error = error {
                print("❌ Firestore insert failed: \(error.localizedDescription)")
            } else {
                print("✅ Firestore insert success!")
                print("📄 Document ID: \(testTodo.id)")
                print("📝 Title: \(testTodo.title)")
                print("👤 User ID: \(testTodo.userId)")

                // Verify by reading back
                docRef.getDocument { document, error in
                    if let document = document, document.exists {
                        print("✅ Verification: Document exists in Firestore")
                        if let data = document.data() {
                            print("📊 Data: \(data)")
                        }
                    } else {
                        print("❌ Verification failed: Document not found")
                    }

                    // Exit after test
                    exit(0)
                }
            }
        }
    }
}

// Run the test
testFirestoreInsert()

// Keep the program running
RunLoop.main.run()
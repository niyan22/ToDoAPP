import SwiftUI
import FirebaseCore

@main
struct ToDoApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

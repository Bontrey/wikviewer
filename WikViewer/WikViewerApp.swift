import SwiftUI

@main
struct WikViewerApp: App {
    @StateObject private var databaseManager = DatabaseManager()

    var body: some Scene {
        WindowGroup {
            ContentView(databaseManager: databaseManager)
                .onAppear {
                    databaseManager.loadDictionary()
                }
        }
    }
}

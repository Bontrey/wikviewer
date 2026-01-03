import SwiftUI

@main
struct WikViewerApp: App {
    @StateObject private var databaseManager: DatabaseManager
    @StateObject private var historyManager: HistoryManager

    init() {
        let dbManager = DatabaseManager()
        _databaseManager = StateObject(wrappedValue: dbManager)
        _historyManager = StateObject(wrappedValue: HistoryManager(databaseManager: dbManager))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(databaseManager: databaseManager, historyManager: historyManager)
                .environmentObject(databaseManager)
                .environmentObject(historyManager)
                .task {
                    databaseManager.loadDictionary()
                    // Wait for database to finish loading
                    while databaseManager.isLoading {
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    }
                    // Now load history
                    historyManager.loadHistory()
                }
        }
    }
}

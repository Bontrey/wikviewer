import SwiftUI

struct SearchResultsView: View {
    @ObservedObject var databaseManager: DatabaseManager
    @EnvironmentObject var historyManager: HistoryManager
    let initialQuery: String

    init(databaseManager: DatabaseManager, initialQuery: String) {
        self.databaseManager = databaseManager
        self.initialQuery = initialQuery
    }

    var body: some View {
        ContentView(
            databaseManager: databaseManager,
            historyManager: historyManager,
            initialQuery: initialQuery,
            navigationTitle: "Find Results",
            titleDisplayMode: .inline,
            showAllEntriesWhenEmpty: false,
            embedInNavigationStack: false,
            showPopToRootButton: true
        )
    }
}

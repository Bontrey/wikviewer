import SwiftUI

struct SearchResultsView: View {
    @ObservedObject var databaseManager: DatabaseManager
    let initialQuery: String

    init(databaseManager: DatabaseManager, initialQuery: String) {
        self.databaseManager = databaseManager
        self.initialQuery = initialQuery
    }

    var body: some View {
        ContentView(
            databaseManager: databaseManager,
            initialQuery: initialQuery,
            navigationTitle: "Find Results",
            titleDisplayMode: .inline,
            showAllEntriesWhenEmpty: false
        )
    }
}

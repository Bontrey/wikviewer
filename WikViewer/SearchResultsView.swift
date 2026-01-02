import SwiftUI

struct SearchResultsView: View {
    @ObservedObject var databaseManager: DatabaseManager
    @State private var searchText: String
    @State private var searchResults: [CoalescedEntry] = []

    init(databaseManager: DatabaseManager, initialQuery: String) {
        self.databaseManager = databaseManager
        self._searchText = State(initialValue: initialQuery)
    }

    var body: some View {
        List(searchResults) { entry in
            NavigationLink(destination: DetailView(coalescedEntry: entry)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.word)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(entry.primaryGloss)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    Text(entry.partsOfSpeech)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Search Results")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search words...")
        .onChange(of: searchText) { _, newValue in
            performSearch(query: newValue)
        }
        .onAppear {
            performSearch(query: searchText)
        }
    }

    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        databaseManager.searchDictionary(query: query) { results in
            searchResults = results
        }
    }
}

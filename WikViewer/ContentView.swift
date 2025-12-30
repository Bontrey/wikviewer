import SwiftUI

struct ContentView: View {
    @ObservedObject var databaseManager: DatabaseManager
    @State private var searchText = ""
    @State private var searchResults: [DictionaryEntry] = []

    var displayedEntries: [DictionaryEntry] {
        if searchText.isEmpty {
            return databaseManager.entries
        } else {
            return searchResults
        }
    }

    var body: some View {
        NavigationStack {
            List(displayedEntries) { entry in
                NavigationLink(destination: DetailView(entry: entry)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.word)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(entry.gloss)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Dictionary")
            .searchable(text: $searchText, prompt: "Search words...")
            .onChange(of: searchText) { _, newValue in
                if !newValue.isEmpty {
                    performSearch(query: newValue)
                } else {
                    searchResults = []
                }
            }
        }
    }

    private func performSearch(query: String) {
        databaseManager.searchDictionary(query: query) { results in
            searchResults = results
        }
    }
}

#Preview {
    ContentView(databaseManager: DatabaseManager())
}

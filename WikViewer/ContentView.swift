import SwiftUI

struct ContentView: View {
    @ObservedObject var databaseManager: DatabaseManager
    @State private var searchText = ""
    @State private var searchResults: [CoalescedEntry] = []

    var displayedEntries: [CoalescedEntry] {
        if searchText.isEmpty {
            return databaseManager.coalescedEntries
        } else {
            return searchResults
        }
    }

    var body: some View {
        NavigationStack {
            List(displayedEntries) { entry in
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
            .navigationTitle("Wiktionnaire")
            .searchable(text: $searchText, prompt: "Find words...")
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

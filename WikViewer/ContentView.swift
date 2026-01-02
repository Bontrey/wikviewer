import SwiftUI

struct ContentView: View {
    @ObservedObject var databaseManager: DatabaseManager
    @State private var searchText = ""
    @State private var searchResults: [CoalescedEntry] = []
    @State private var currentSearchID = 0
    @State private var useTrigramIndex = false

    var displayedEntries: [CoalescedEntry] {
        let entries = searchText.isEmpty ? databaseManager.coalescedEntries : searchResults
        return entries.sorted { $0.word.count < $1.word.count }
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
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Image(systemName: useTrigramIndex ? "text.magnifyingglass" : "textformat.abc")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Toggle("", isOn: $useTrigramIndex)
                        .toggleStyle(.switch)
                        .labelsHidden()
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemBackground))
            }
            .task(id: searchText) {
                if searchText.isEmpty {
                    searchResults = []
                } else {
                    currentSearchID += 1
                    await performSearch(query: searchText, searchID: currentSearchID)
                }
            }
            .task(id: useTrigramIndex) {
                // Re-run search when index type changes
                if !searchText.isEmpty {
                    currentSearchID += 1
                    await performSearch(query: searchText, searchID: currentSearchID)
                }
            }
        }
    }

    private func performSearch(query: String, searchID: Int) async {
        await withCheckedContinuation { continuation in
            databaseManager.searchDictionary(query: query, useTrigramIndex: useTrigramIndex) { results in
                Task { @MainActor in
                    // Only update if this is still the current search
                    if searchID == self.currentSearchID {
                        self.searchResults = results
                    }
                    continuation.resume()
                }
            }
        }
    }
}

#Preview {
    ContentView(databaseManager: DatabaseManager())
}

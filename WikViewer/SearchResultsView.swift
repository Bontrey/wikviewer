import SwiftUI

struct SearchResultsView: View {
    @ObservedObject var databaseManager: DatabaseManager
    @State private var searchText: String
    @State private var searchResults: [CoalescedEntry] = []
    @State private var currentSearchID = 0
    @State private var useTrigramIndex = false

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
        .navigationTitle("Find Results")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Find words...")
        .safeAreaInset(edge: .bottom) {
            HStack {
                Image(systemName: useTrigramIndex ? "eye" : "eye.half.closed")
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
            if !searchText.isEmpty {
                currentSearchID += 1
                await performSearch(query: searchText, searchID: currentSearchID)
            } else {
                searchResults = []
            }
        }
        .task(id: useTrigramIndex) {
            // Re-run search when index type changes
            if !searchText.isEmpty {
                currentSearchID += 1
                await performSearch(query: searchText, searchID: currentSearchID)
            }
        }
        .onAppear {
            if !searchText.isEmpty {
                currentSearchID += 1
                Task {
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
                        self.searchResults = results.sorted { $0.word.count < $1.word.count }
                    }
                    continuation.resume()
                }
            }
        }
    }
}

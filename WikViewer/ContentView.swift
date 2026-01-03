import SwiftUI

struct ContentView: View {
    @ObservedObject var databaseManager: DatabaseManager
    @State private var searchText: String
    @State private var searchResults: [CoalescedEntry] = []
    @State private var currentSearchID = 0
    @State private var useTrigramIndex = false

    let navigationTitle: String
    let titleDisplayMode: NavigationBarItem.TitleDisplayMode
    let showAllEntriesWhenEmpty: Bool

    init(
        databaseManager: DatabaseManager,
        initialQuery: String = "",
        navigationTitle: String = "Wiktionnaire",
        titleDisplayMode: NavigationBarItem.TitleDisplayMode = .large,
        showAllEntriesWhenEmpty: Bool = true
    ) {
        self.databaseManager = databaseManager
        self._searchText = State(initialValue: initialQuery)
        self.navigationTitle = navigationTitle
        self.titleDisplayMode = titleDisplayMode
        self.showAllEntriesWhenEmpty = showAllEntriesWhenEmpty
    }

    var displayedEntries: [CoalescedEntry] {
        let entries = searchText.isEmpty && showAllEntriesWhenEmpty ? databaseManager.coalescedEntries : searchResults
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
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(titleDisplayMode)
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
            .onAppear {
                if !searchText.isEmpty {
                    currentSearchID += 1
                    Task {
                        await performSearch(query: searchText, searchID: currentSearchID)
                    }
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

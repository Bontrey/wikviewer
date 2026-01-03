import SwiftUI

struct SearchResultsView: View {
    @ObservedObject var databaseManager: DatabaseManager
    @State private var searchText: String
    @State private var searchResults: [CoalescedEntry] = []
    @State private var currentSearchID = 0
    @State private var useTrigramIndex = false
    @FocusState private var isSearchFocused: Bool

    init(databaseManager: DatabaseManager, initialQuery: String) {
        self.databaseManager = databaseManager
        self._searchText = State(initialValue: initialQuery)
    }

    var displayedEntries: [CoalescedEntry] {
        return searchResults.sorted { $0.word.count < $1.word.count }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Find words...", text: $searchText)
                    .focused($isSearchFocused)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.vertical, 8)

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
            .simultaneousGesture(
                DragGesture(minimumDistance: 10).onChanged { _ in
                    isSearchFocused = false
                }
            )
        }
        .navigationTitle("Find Results")
        .navigationBarTitleDisplayMode(.inline)
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
            }
        }
        .task(id: useTrigramIndex) {
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
                    if searchID == self.currentSearchID {
                        self.searchResults = results
                    }
                    continuation.resume()
                }
            }
        }
    }
}

import SwiftUI

struct ContentView: View {
    @ObservedObject var databaseManager: DatabaseManager
    @ObservedObject var historyManager: HistoryManager
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @State private var searchText: String
    @State private var searchResults: [CoalescedEntry] = []
    @State private var currentSearchID = 0
    @State private var useTrigramIndex = false
    @FocusState private var isSearchFocused: Bool
    @State private var selectedHistoryWord: String?
    @State private var loadedHistoryEntry: CoalescedEntry?

    let navigationTitle: String
    let titleDisplayMode: NavigationBarItem.TitleDisplayMode
    let showAllEntriesWhenEmpty: Bool
    let embedInNavigationStack: Bool
    let showPopToRootButton: Bool

    init(
        databaseManager: DatabaseManager,
        historyManager: HistoryManager,
        initialQuery: String = "",
        navigationTitle: String = "Wiktionnaire",
        titleDisplayMode: NavigationBarItem.TitleDisplayMode = .large,
        showAllEntriesWhenEmpty: Bool = true,
        embedInNavigationStack: Bool = true,
        showPopToRootButton: Bool = false
    ) {
        self.databaseManager = databaseManager
        self.historyManager = historyManager
        self._searchText = State(initialValue: initialQuery)
        self.navigationTitle = navigationTitle
        self.titleDisplayMode = titleDisplayMode
        self.showAllEntriesWhenEmpty = showAllEntriesWhenEmpty
        self.embedInNavigationStack = embedInNavigationStack
        self.showPopToRootButton = showPopToRootButton
    }

    var displayedEntries: [CoalescedEntry] {
        let entries: [CoalescedEntry]
        if !searchText.isEmpty {
            // Search is active: show search results
            entries = searchResults.sorted { $0.word.count < $1.word.count }
        } else if showAllEntriesWhenEmpty {
            // Search is empty and we should show defaults
            // Show recent history in chronological order (most recent first)
            entries = historyManager.recentEntries
        } else {
            // Search is empty but we shouldn't show anything (SearchResultsView case)
            entries = []
        }
        return entries
    }

    var isShowingHistory: Bool {
        searchText.isEmpty && showAllEntriesWhenEmpty
    }

    var body: some View {
        Group {
            if databaseManager.isLoading {
                loadingView
            } else if embedInNavigationStack {
                NavigationStack {
                    searchContent
                        .environmentObject(historyManager)
                }
            } else {
                searchContent
                    .environmentObject(historyManager)
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading dictionary...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }

    private var searchContent: some View {
        VStack(spacing: 0) {
            // Custom search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Find words...", text: $searchText)
                    .focused($isSearchFocused)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)

                Button(action: { useTrigramIndex.toggle() }) {
                    Image(systemName: useTrigramIndex ? "eye" : "eye.half.closed")
                        .foregroundColor(.secondary)
                }

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

            List {
                if isShowingHistory {
                    Section {
                        if displayedEntries.isEmpty {
                            // Placeholder when history is empty
                            Text("Words you look up will appear here")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 12)
                                .listRowSeparator(.hidden)
                        } else {
                            ForEach(displayedEntries) { entry in
                                Button(action: {
                                    // Trigger database search for full entry
                                    selectedHistoryWord = entry.word
                                }) {
                                    HStack {
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
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } header: {
                        Text("Recently Viewed")
                    }
                } else {
                    // Search results or SearchResultsView
                    ForEach(displayedEntries) { entry in
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
                }
            }
            .listStyle(.plain)
            .simultaneousGesture(
                DragGesture(minimumDistance: 10).onChanged { _ in
                    isSearchFocused = false
                }
            )
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(titleDisplayMode)
        .toolbar {
            if showPopToRootButton {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        navigationCoordinator.popToRoot()
                    }) {
                        Image(systemName: "house")
                    }
                }
            }
        }
        .navigationDestination(item: $loadedHistoryEntry) { entry in
            DetailView(coalescedEntry: entry)
        }
        .onChange(of: navigationCoordinator.shouldPopToRoot) { _, shouldPop in
            if shouldPop {
                searchText = ""
                loadedHistoryEntry = nil
            }
        }
        .task(id: selectedHistoryWord) {
            // When a history word is selected, search the database for the full entry
            if let word = selectedHistoryWord {
                await loadFullEntryFromDatabase(word: word)
            }
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

    private func performSearch(query: String, searchID: Int) async {
        // Strip l' or d' prefix if present (typographic apostrophe)
        let normalizedQuery: String
        let lowercased = query.lowercased()
        if lowercased.count > 2 && ( lowercased.hasPrefix("l’") || lowercased.hasPrefix("d’")) {
            normalizedQuery = String(query.dropFirst(2))
        } else {
            normalizedQuery = query
        }

        await withCheckedContinuation { continuation in
            databaseManager.searchDictionary(query: normalizedQuery, useTrigramIndex: useTrigramIndex) { results in
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

    private func loadFullEntryFromDatabase(word: String) async {
        await withCheckedContinuation { continuation in
            databaseManager.searchDictionary(query: word, useTrigramIndex: false) { results in
                Task { @MainActor in
                    // Find exact match (case-sensitive)
                    if let match = results.first(where: { $0.word == word }) {
                        self.loadedHistoryEntry = match
                    }
                    // Clear the trigger to prevent re-triggering
                    self.selectedHistoryWord = nil
                    continuation.resume()
                }
            }
        }
    }
}

#Preview {
    let dbManager = DatabaseManager()
    return ContentView(
        databaseManager: dbManager,
        historyManager: HistoryManager(databaseManager: dbManager)
    )
    .environmentObject(NavigationCoordinator())
}

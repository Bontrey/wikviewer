import SwiftUI

enum FindDestination: Hashable {
    case entry(CoalescedEntry)
    case searchResults(String)
}

struct DetailView: View {
    let coalescedEntry: CoalescedEntry
    @EnvironmentObject var databaseManager: DatabaseManager
    @EnvironmentObject var historyManager: HistoryManager
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @State private var selection: TextSelection? = nil
    @State private var findDestination: FindDestination? = nil
    @State private var hasRecordedView = false

    /// Returns the shared etymology if all senses with an etymology have the same one, otherwise nil
    private var sharedEtymology: String? {
        let etymologies = coalescedEntry.senses.compactMap { $0.etymology }
        guard !etymologies.isEmpty else { return nil }
        let uniqueEtymologies = Set(etymologies)
        return uniqueEtymologies.count == 1 ? etymologies.first : nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Word header
                SelectableText(text: coalescedEntry.word, selection: $selection, onFind: handleFind, onSearch: handleSearch)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Shared etymology at top if all senses have the same one
                if let etymology = sharedEtymology {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Etymology")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        SelectableText(text: etymology, selection: $selection, onFind: handleFind, onSearch: handleSearch)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Divider()

                // Iterate through each part of speech group
                ForEach(coalescedEntry.groupedByPartOfSpeech(), id: \.pos) { group in
                    PartOfSpeechSection(
                        partOfSpeech: group.pos,
                        senses: group.senses,
                        hideEtymology: sharedEtymology != nil,
                        selection: $selection,
                        onFind: handleFind,
                        onSearch: handleSearch
                    )
                }

                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    navigationCoordinator.popToRoot()
                }) {
                    Image(systemName: "house")
                }
            }
        }
        .navigationDestination(item: $findDestination) { destination in
            switch destination {
            case .entry(let entry):
                DetailView(coalescedEntry: entry)
            case .searchResults(let query):
                SearchResultsView(databaseManager: databaseManager, initialQuery: query)
            }
        }
        .onChange(of: navigationCoordinator.shouldPopToRoot) { _, shouldPop in
            if shouldPop {
                findDestination = nil
            }
        }
        .onAppear {
            // Only record the view on initial appearance (push), not when popping back
            if !hasRecordedView {
                historyManager.recordView(of: coalescedEntry)
                hasRecordedView = true
            }
        }
    }

    private func handleFind(selectedText: String) {
        // Normalize the query by stripping l' or d' prefix if present
        let normalizedQuery: String
        let lowercased = selectedText.lowercased()
        if lowercased.count > 2 && (lowercased.hasPrefix("l’") || lowercased.hasPrefix("d’") ||
            lowercased.hasPrefix("l'") || lowercased.hasPrefix("d'")) {
            normalizedQuery = String(selectedText.dropFirst(2))
        } else {
            normalizedQuery = selectedText
        }

        databaseManager.searchDictionary(query: normalizedQuery) { results in
            // Check if there's exactly 1 exact match (same length as normalized query)
            let exactMatches = results.filter { $0.word.count == normalizedQuery.count }

            if exactMatches.count == 1, let exactMatch = exactMatches.first {
                // Exactly one exact match: navigate directly to the entry
                findDestination = .entry(exactMatch)
            } else if exactMatches.count > 1 {
                // Multiple exact matches: first check for case-sensitive equality
                let caseSensitiveMatches = exactMatches.filter { $0.word == normalizedQuery }

                if caseSensitiveMatches.count == 1, let match = caseSensitiveMatches.first {
                    // Exactly one case-sensitive match: navigate directly to the entry
                    findDestination = .entry(match)
                } else {
                    // Multiple or no case-sensitive matches: check for case-insensitive equality to handle accents
                    let normalizedQueryLower = normalizedQuery.lowercased()
                    let caseInsensitiveMatches = exactMatches.filter { $0.word.lowercased() == normalizedQueryLower }

                    if caseInsensitiveMatches.count == 1, let match = caseInsensitiveMatches.first {
                        // Exactly one case-insensitive match: navigate directly to the entry
                        findDestination = .entry(match)
                    } else {
                        // 0 or multiple case-insensitive matches: show search results view
                        findDestination = .searchResults(selectedText)
                    }
                }
            } else {
                // 0 exact matches: show search results view
                findDestination = .searchResults(selectedText)
            }
        }
    }

    private func handleSearch(selectedText: String) {
        // Always navigate to search results view without optimization
        findDestination = .searchResults(selectedText)
    }
}

struct PartOfSpeechSection: View {
    let partOfSpeech: String
    let senses: [DictionarySense]
    var hideEtymology: Bool = false
    @Binding var selection: TextSelection?
    var onFind: ((String) -> Void)?
    var onSearch: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Show each sense with numbering if multiple
            ForEach(senses.indices, id: \.self) { index in
                SenseView(
                    sense: senses[index],
                    partOfSpeech: partOfSpeech,
                    number: senses.count > 1 ? index + 1 : nil,
                    hideEtymology: hideEtymology,
                    selection: $selection,
                    onFind: onFind,
                    onSearch: onSearch
                )

                if index < senses.count - 1 {
                    Divider()
                        .padding(.leading, 20)
                }
            }
        }
        .padding(.bottom, 8)
    }
}

struct SenseView: View {
    let sense: DictionarySense
    let partOfSpeech: String
    let number: Int?
    var hideEtymology: Bool = false
    @Binding var selection: TextSelection?
    var onFind: ((String) -> Void)?
    var onSearch: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Part of speech header with number if provided
            if let number = number {
                Text("\(partOfSpeech) \(number)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                Text(partOfSpeech)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .italic()
            }

            // Definition
            VStack(alignment: .leading, spacing: 4) {
                Text("Definition")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                SelectableText(text: sense.definition, selection: $selection, onFind: onFind, onSearch: onSearch)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Examples
            if !sense.examples.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Examples")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    ForEach(sense.examples.indices, id: \.self) { index in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)

                            SelectableText(text: sense.examples[index], selection: $selection, onFind: onFind, onSearch: onSearch)
                                .font(.body)
                                .italic()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }

            // Etymology (only show if not hidden at top level)
            if !hideEtymology, let etymology = sense.etymology {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Etymology")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    SelectableText(text: etymology, selection: $selection, onFind: onFind, onSearch: onSearch)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

#Preview {
    let dbManager = DatabaseManager()
    return NavigationStack {
        DetailView(coalescedEntry: CoalescedEntry(
            id: UUID(),
            word: "run",
            senses: [
                DictionarySense(from: DictionaryEntry.sampleData[0])
            ]
        ))
        .environmentObject(dbManager)
        .environmentObject(HistoryManager(databaseManager: dbManager))
        .environmentObject(NavigationCoordinator())
    }
}

import SwiftUI

enum FindDestination: Hashable {
    case entry(CoalescedEntry)
    case searchResults(String)
}

struct DetailView: View {
    let coalescedEntry: CoalescedEntry
    @EnvironmentObject var databaseManager: DatabaseManager
    @EnvironmentObject var historyManager: HistoryManager
    @State private var selection: TextSelection? = nil
    @State private var findDestination: FindDestination? = nil
    @State private var hasRecordedView = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Word header
                Text(coalescedEntry.word)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Divider()

                // Iterate through each part of speech group
                ForEach(coalescedEntry.groupedByPartOfSpeech(), id: \.pos) { group in
                    PartOfSpeechSection(
                        partOfSpeech: group.pos,
                        senses: group.senses,
                        selection: $selection,
                        onFind: handleFind
                    )
                }

                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $findDestination) { destination in
            switch destination {
            case .entry(let entry):
                DetailView(coalescedEntry: entry)
            case .searchResults(let query):
                SearchResultsView(databaseManager: databaseManager, initialQuery: query)
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
        databaseManager.searchDictionary(query: selectedText) { results in
            if results.count == 1, let singleResult = results.first {
                // Single result: navigate directly to the entry
                findDestination = .entry(singleResult)
            } else {
                // 0 or multiple results: show search results view
                findDestination = .searchResults(selectedText)
            }
        }
    }
}

struct PartOfSpeechSection: View {
    let partOfSpeech: String
    let senses: [DictionarySense]
    @Binding var selection: TextSelection?
    var onFind: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Part of speech header
            Text(partOfSpeech)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .italic()

            // Show each sense with numbering if multiple
            ForEach(senses.indices, id: \.self) { index in
                SenseView(
                    sense: senses[index],
                    number: senses.count > 1 ? index + 1 : nil,
                    selection: $selection,
                    onFind: onFind
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
    let number: Int?
    @Binding var selection: TextSelection?
    var onFind: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Sense number if provided
            if let number = number {
                Text("\(number).")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            // Definition
            VStack(alignment: .leading, spacing: 4) {
                Text("Definition")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                SelectableText(text: sense.definition, selection: $selection, onFind: onFind)
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

                            SelectableText(text: sense.examples[index], selection: $selection, onFind: onFind)
                                .font(.body)
                                .italic()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }

            // Etymology
            if let etymology = sense.etymology {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Etymology")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    SelectableText(text: etymology, selection: $selection, onFind: onFind)
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
    }
}

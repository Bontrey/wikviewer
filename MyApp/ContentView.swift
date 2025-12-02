import SwiftUI

struct ContentView: View {
    @State private var searchText = ""
    @State private var entries = DictionaryEntry.sampleData

    var filteredEntries: [DictionaryEntry] {
        if searchText.isEmpty {
            return entries
        } else {
            return entries.filter { entry in
                entry.word.localizedCaseInsensitiveContains(searchText) ||
                entry.gloss.localizedCaseInsensitiveContains(searchText) ||
                entry.definition.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredEntries) { entry in
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
            .searchable(text: $searchText, prompt: "Search words, definitions...")
        }
    }
}

#Preview {
    ContentView()
}

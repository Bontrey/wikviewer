import SwiftUI

struct ContentView: View {
    @ObservedObject var databaseManager: DatabaseManager
    @State private var searchText = ""

    var filteredEntries: [DictionaryEntry] {
        if searchText.isEmpty {
            return databaseManager.entries
        } else {
            return databaseManager.entries.filter { entry in
                entry.word.localizedCaseInsensitiveContains(searchText)
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
            .searchable(text: $searchText, prompt: "Search words...")
        }
    }
}

#Preview {
    ContentView(databaseManager: DatabaseManager())
}

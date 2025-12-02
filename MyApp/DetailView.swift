import SwiftUI

struct DetailView: View {
    let entry: DictionaryEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Word and part of speech
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.word)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(entry.partOfSpeech)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                }

                Divider()

                // Gloss
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Definition")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    Text(entry.gloss)
                        .font(.body)
                }

                // Definition
                VStack(alignment: .leading, spacing: 4) {
                    Text("Definition")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    Text(entry.definition)
                        .font(.body)
                }

                // Examples
                if !entry.examples.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Examples")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        ForEach(entry.examples.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).")
                                    .foregroundColor(.secondary)
                                    .fontWeight(.medium)

                                Text(entry.examples[index])
                                    .font(.body)
                                    .italic()
                            }
                        }
                    }
                }

                // Etymology
                if let etymology = entry.etymology {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Etymology")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(etymology)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        DetailView(entry: DictionaryEntry.sampleData[0])
    }
}

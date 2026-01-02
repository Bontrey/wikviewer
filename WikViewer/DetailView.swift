import SwiftUI

struct DetailView: View {
    let coalescedEntry: CoalescedEntry

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
                        senses: group.senses
                    )
                }

                Spacer()
            }
            .padding()
        }
        .textSelection(.enabled)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PartOfSpeechSection: View {
    let partOfSpeech: String
    let senses: [DictionarySense]

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
                    number: senses.count > 1 ? index + 1 : nil
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

                Text(sense.definition)
                    .font(.body)
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

                            Text(sense.examples[index])
                                .font(.body)
                                .italic()
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

                    Text(etymology)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DetailView(coalescedEntry: CoalescedEntry(
            id: UUID(),
            word: "run",
            senses: [
                DictionarySense(from: DictionaryEntry.sampleData[0])
            ]
        ))
    }
}

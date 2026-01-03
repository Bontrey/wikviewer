import Foundation

struct DictionaryEntry: Identifiable {
    let id: UUID
    let word: String
    let gloss: String
    let partOfSpeech: String
    let definition: String
    let examples: [String]
    let etymology: String?

    init(word: String, gloss: String, partOfSpeech: String, definition: String, examples: [String] = [], etymology: String? = nil) {
        self.id = UUID()
        self.word = word
        self.gloss = gloss
        self.partOfSpeech = partOfSpeech
        self.definition = definition
        self.examples = examples
        self.etymology = etymology
    }
}

// MARK: - DictionarySense

struct DictionarySense: Identifiable, Hashable {
    let id: UUID
    let partOfSpeech: String
    let gloss: String
    let definition: String
    let examples: [String]
    let etymology: String?

    init(from entry: DictionaryEntry) {
        self.id = entry.id
        self.partOfSpeech = entry.partOfSpeech
        self.gloss = entry.gloss
        self.definition = entry.definition
        self.examples = entry.examples
        self.etymology = entry.etymology
    }

    init(id: UUID, partOfSpeech: String, gloss: String, definition: String, examples: [String], etymology: String?) {
        self.id = id
        self.partOfSpeech = partOfSpeech
        self.gloss = gloss
        self.definition = definition
        self.examples = examples
        self.etymology = etymology
    }

    static func == (lhs: DictionarySense, rhs: DictionarySense) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - CoalescedEntry

struct CoalescedEntry: Identifiable, Hashable {
    let id: UUID
    let word: String
    let senses: [DictionarySense]

    var primaryGloss: String {
        senses.first?.gloss ?? ""
    }

    var partsOfSpeech: String {
        let uniquePOS = Set(senses.map { $0.partOfSpeech })
        return Array(uniquePOS).sorted().joined(separator: ", ")
    }

    func groupedByPartOfSpeech() -> [(pos: String, senses: [DictionarySense])] {
        let grouped = Dictionary(grouping: senses, by: { $0.partOfSpeech })
        return grouped.sorted { $0.key < $1.key }
            .map { (pos: $0.key, senses: $0.value) }
    }

    static func == (lhs: CoalescedEntry, rhs: CoalescedEntry) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Sample Data

// Sample data for testing
extension DictionaryEntry {
    static let sampleData: [DictionaryEntry] = [
        DictionaryEntry(
            word: "serendipity",
            gloss: "finding something good without looking for it",
            partOfSpeech: "noun",
            definition: "The occurrence and development of events by chance in a happy or beneficial way.",
            examples: [
                "A fortunate stroke of serendipity brought the two old friends together after years apart.",
                "Their meeting was pure serendipity."
            ],
            etymology: "Coined by Horace Walpole in 1754"
        ),
        DictionaryEntry(
            word: "ephemeral",
            gloss: "lasting for a very short time",
            partOfSpeech: "adjective",
            definition: "Lasting for a very short time; transitory.",
            examples: [
                "The ephemeral nature of fashion trends makes it hard to keep up.",
                "Morning dew is ephemeral, disappearing as soon as the sun rises."
            ],
            etymology: "From Greek ephēmeros 'lasting only a day'"
        ),
        DictionaryEntry(
            word: "ubiquitous",
            gloss: "present, appearing, or found everywhere",
            partOfSpeech: "adjective",
            definition: "Present, appearing, or found everywhere; widespread.",
            examples: [
                "Smartphones have become ubiquitous in modern society.",
                "Coffee shops are ubiquitous in this neighborhood."
            ],
            etymology: "From Latin ubique 'everywhere'"
        ),
        DictionaryEntry(
            word: "pragmatic",
            gloss: "dealing with things sensibly and realistically",
            partOfSpeech: "adjective",
            definition: "Dealing with things sensibly and realistically in a way that is based on practical rather than theoretical considerations.",
            examples: [
                "We need to take a pragmatic approach to solving this problem.",
                "Her pragmatic nature made her an excellent project manager."
            ],
            etymology: "From Greek pragma 'deed, act'"
        ),
        DictionaryEntry(
            word: "verbose",
            gloss: "using more words than needed",
            partOfSpeech: "adjective",
            definition: "Using or expressed in more words than are needed.",
            examples: [
                "His writing style is too verbose and could be more concise.",
                "The verbose explanation confused rather than clarified the concept."
            ],
            etymology: "From Latin verbosus, from verbum 'word'"
        ),
        DictionaryEntry(
            word: "ameliorate",
            gloss: "make something bad or unsatisfactory better",
            partOfSpeech: "verb",
            definition: "To make something bad or unsatisfactory better; improve.",
            examples: [
                "The new policies were designed to ameliorate working conditions.",
                "Medication can help ameliorate the symptoms."
            ],
            etymology: "From Latin meliorare 'make better'"
        ),
        DictionaryEntry(
            word: "cacophony",
            gloss: "a harsh, discordant mixture of sounds",
            partOfSpeech: "noun",
            definition: "A harsh, discordant mixture of sounds.",
            examples: [
                "The cacophony of car horns filled the city streets.",
                "The orchestra's warm-up created a cacophony of sounds."
            ],
            etymology: "From Greek kakophōnia, from kakos 'bad' + phōnē 'sound'"
        ),
        DictionaryEntry(
            word: "eloquent",
            gloss: "fluent or persuasive in speaking or writing",
            partOfSpeech: "adjective",
            definition: "Fluent or persuasive in speaking or writing; clearly expressing or indicating something.",
            examples: [
                "She gave an eloquent speech that moved the audience.",
                "His eloquent writing style captivated readers."
            ],
            etymology: "From Latin eloquens, from eloqui 'speak out'"
        ),
        DictionaryEntry(
            word: "meticulous",
            gloss: "showing great attention to detail",
            partOfSpeech: "adjective",
            definition: "Showing great attention to detail; very careful and precise.",
            examples: [
                "She kept meticulous records of all expenses.",
                "The architect's meticulous planning ensured the project's success."
            ],
            etymology: "From Latin meticulosus 'fearful'"
        ),
        DictionaryEntry(
            word: "pervasive",
            gloss: "spreading widely throughout an area or group",
            partOfSpeech: "adjective",
            definition: "Spreading widely throughout an area or a group of people; present everywhere.",
            examples: [
                "There was a pervasive sense of optimism in the room.",
                "The pervasive influence of technology has changed how we communicate."
            ],
            etymology: "From Latin pervasivus, from pervadere 'spread through'"
        )
    ]
}

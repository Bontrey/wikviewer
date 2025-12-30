import Foundation

struct EntryCoalescer {
    /// Coalesces an array of DictionaryEntry into CoalescedEntry objects
    /// Groups entries by exact word match (case-sensitive)
    static func coalesce(_ entries: [DictionaryEntry]) -> [CoalescedEntry] {
        // Group by word (case-sensitive)
        let grouped = Dictionary(grouping: entries, by: { $0.word })

        // Convert to CoalescedEntry
        let coalesced = grouped.map { (word, entries) -> CoalescedEntry in
            let senses = entries.map { DictionarySense(from: $0) }
            return CoalescedEntry(
                id: UUID(),
                word: word,
                senses: senses
            )
        }

        // Sort by word alphabetically
        return coalesced.sorted { $0.word.localizedCaseInsensitiveCompare($1.word) == .orderedAscending }
    }
}

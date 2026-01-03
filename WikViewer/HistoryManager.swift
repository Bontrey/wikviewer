import Foundation
import Combine

// Lightweight struct for storing history entries (decoupled from database)
struct HistoryEntry: Codable, Identifiable {
    let id: UUID
    let word: String
    let primaryGloss: String
    let partsOfSpeech: String

    init(from coalescedEntry: CoalescedEntry) {
        self.id = UUID() // Generate new UUID for history entry
        self.word = coalescedEntry.word
        self.primaryGloss = coalescedEntry.primaryGloss
        self.partsOfSpeech = coalescedEntry.partsOfSpeech
    }

    // Convert back to CoalescedEntry for display (without full sense data)
    func toCoalescedEntry() -> CoalescedEntry {
        // Create a minimal DictionarySense for display purposes
        let sense = DictionarySense(
            id: UUID(),
            partOfSpeech: partsOfSpeech.components(separatedBy: ", ").first ?? "",
            gloss: primaryGloss,
            definition: primaryGloss,
            examples: [],
            etymology: nil
        )
        return CoalescedEntry(id: id, word: word, senses: [sense])
    }
}

class HistoryManager: ObservableObject {
    @Published private(set) var recentEntries: [CoalescedEntry] = []

    private let maxHistorySize = 20
    private let historyKey = "viewingHistory"
    private let databaseManager: DatabaseManager

    init(databaseManager: DatabaseManager) {
        self.databaseManager = databaseManager
    }

    // MARK: - Public API

    /// Records that a user viewed a dictionary entry
    /// Adds to front of history, removes duplicates, maintains max size
    func recordView(of entry: CoalescedEntry) {
        print("HistoryManager: Recording view of '\(entry.word)'")

        // Remove existing occurrence if present (deduplication)
        recentEntries.removeAll { $0.word == entry.word }

        // Add to front (most recent first)
        recentEntries.insert(entry, at: 0)

        // Trim to max size
        if recentEntries.count > maxHistorySize {
            recentEntries = Array(recentEntries.prefix(maxHistorySize))
        }

        print("HistoryManager: Now have \(recentEntries.count) entries in history")

        // Persist to UserDefaults
        persistHistory()
    }

    /// Loads viewing history from UserDefaults
    /// No database lookup needed - history entries are self-contained
    func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else {
            recentEntries = []
            print("HistoryManager: No saved history found")
            return
        }

        do {
            let decoder = JSONDecoder()
            let historyEntries = try decoder.decode([HistoryEntry].self, from: data)
            recentEntries = historyEntries.map { $0.toCoalescedEntry() }
            print("HistoryManager: Loaded \(recentEntries.count) entries from history")
        } catch {
            print("HistoryManager: Failed to decode history: \(error)")
            recentEntries = []
        }
    }

    // MARK: - Private Implementation

    /// Persists current history to UserDefaults as JSON
    private func persistHistory() {
        let historyEntries = recentEntries.map { HistoryEntry(from: $0) }

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(historyEntries)
            UserDefaults.standard.set(data, forKey: historyKey)
            print("HistoryManager: Persisted \(historyEntries.count) entries")
        } catch {
            print("HistoryManager: Failed to persist history: \(error)")
        }
    }
}

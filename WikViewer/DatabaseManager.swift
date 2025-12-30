import Foundation
import SQLite3

class DatabaseManager: ObservableObject {
    @Published var entries: [DictionaryEntry] = []
    @Published var coalescedEntries: [CoalescedEntry] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?

    private var db: OpaquePointer?

    func loadDictionary() {
        isLoading = true
        error = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Find dictionary.db in the bundle
            guard let dbPath = self.findDictionaryDatabase() else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.error = NSError(domain: "DatabaseManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database file not found"])
                }
                return
            }

            // Open database
            if sqlite3_open(dbPath, &self.db) != SQLITE_OK {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.error = NSError(domain: "DatabaseManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to open database"])
                }
                return
            }

            // Query entries
            let queryString = "SELECT word, pos, data FROM entries ORDER BY word LIMIT 1000"
            var statement: OpaquePointer?

            if sqlite3_prepare_v2(self.db, queryString, -1, &statement, nil) == SQLITE_OK {
                var loadedEntries: [DictionaryEntry] = []

                while sqlite3_step(statement) == SQLITE_ROW {
                    let word = String(cString: sqlite3_column_text(statement, 0))
                    let pos = sqlite3_column_text(statement, 1).flatMap { String(cString: $0) } ?? "unknown"
                    let jsonData = String(cString: sqlite3_column_text(statement, 2))

                    if let entry = self.parseEntry(word: word, pos: pos, jsonData: jsonData) {
                        loadedEntries.append(entry)
                    }
                }

                sqlite3_finalize(statement)

                DispatchQueue.main.async {
                    self.entries = loadedEntries
                    self.coalescedEntries = EntryCoalescer.coalesce(loadedEntries)
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.error = NSError(domain: "DatabaseManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to prepare query"])
                }
            }

            sqlite3_close(self.db)
            self.db = nil
        }
    }

    func searchDictionary(query: String, completion: @escaping ([CoalescedEntry]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            var results: [DictionaryEntry] = []

            // Find dictionary.db in the bundle
            guard let dbPath = self.findDictionaryDatabase() else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }

            var searchDb: OpaquePointer?

            // Open database
            if sqlite3_open(dbPath, &searchDb) != SQLITE_OK {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }

            // Use FTS5 virtual table and join back to entries for full data
            let queryString = """
                SELECT e.word, e.pos, e.data
                FROM entries_fts f
                JOIN entries e ON f.rowid = e.id
                WHERE f.word MATCH ?
                ORDER BY rank
                LIMIT 100
                """
            var statement: OpaquePointer?

            if sqlite3_prepare_v2(searchDb, queryString, -1, &statement, nil) == SQLITE_OK {
                // Bind the search query with prefix matching
                let searchPattern = query + "*"
                sqlite3_bind_text(statement, 1, (searchPattern as NSString).utf8String, -1, nil)

                while sqlite3_step(statement) == SQLITE_ROW {
                    let word = String(cString: sqlite3_column_text(statement, 0))
                    let pos = sqlite3_column_text(statement, 1).flatMap { String(cString: $0) } ?? "unknown"
                    let jsonData = String(cString: sqlite3_column_text(statement, 2))

                    if let entry = self.parseEntry(word: word, pos: pos, jsonData: jsonData) {
                        results.append(entry)
                    }
                }

                sqlite3_finalize(statement)
            }

            sqlite3_close(searchDb)

            DispatchQueue.main.async {
                let coalesced = EntryCoalescer.coalesce(results)
                completion(coalesced)
            }
        }
    }

    private func parseEntry(word: String, pos: String, jsonData: String) -> DictionaryEntry? {
        guard let data = jsonData.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // Extract gloss from senses
        var gloss = ""
        var definition = ""
        var examples: [String] = []
        var etymology: String?

        if let senses = json["senses"] as? [[String: Any]], let firstSense = senses.first {
            if let glosses = firstSense["glosses"] as? [String], let firstGloss = glosses.first {
                gloss = firstGloss
            }

            // Get definition from raw_glosses or glosses
            if let rawGlosses = firstSense["raw_glosses"] as? [String], let firstDef = rawGlosses.first {
                definition = firstDef
            } else if let glosses = firstSense["glosses"] as? [String] {
                definition = glosses.joined(separator: "; ")
            }

            // Extract examples
            if let examplesList = firstSense["examples"] as? [[String: Any]] {
                examples = examplesList.compactMap { example in
                    if let text = example["text"] as? String {
                        return text
                    }
                    return nil
                }
            }
        }

        // Extract etymology
        if let etymologyTexts = json["etymology_texts"] as? [String], !etymologyTexts.isEmpty {
            etymology = etymologyTexts.joined(separator: " ")
        }

        return DictionaryEntry(
            word: word,
            gloss: gloss.isEmpty ? definition : gloss,
            partOfSpeech: pos,
            definition: definition.isEmpty ? gloss : definition,
            examples: examples,
            etymology: etymology
        )
    }

    private func findDictionaryDatabase() -> String? {
        // Load from embedded bundle resource
        return Bundle.main.path(forResource: "dictionary", ofType: "db")
    }
}

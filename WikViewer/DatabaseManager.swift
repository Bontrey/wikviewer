import Foundation
import SQLite3
import Compression

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

    func searchDictionary(query: String, useTrigramIndex: Bool = false, completion: @escaping ([CoalescedEntry]) -> Void) {
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

            // Choose appropriate FTS table and query based on user selection
            // Default (non-trigram): uses prefix matching with "*"
            // Trigram: uses substring matching without prefix operator
            let ftsTable = useTrigramIndex ? "entries_fts_trigram" : "entries_fts"
            let searchQuery = useTrigramIndex ? query : "\(query)*"

            let queryString = """
                SELECT e.word, e.pos, e.data
                FROM \(ftsTable) f
                JOIN entries e ON f.rowid = e.id
                WHERE f.word MATCH ?
                ORDER BY rank
                LIMIT 100
                """
            var statement: OpaquePointer?

            if sqlite3_prepare_v2(searchDb, queryString, -1, &statement, nil) == SQLITE_OK {
                // Bind the search query
                sqlite3_bind_text(statement, 1, (searchQuery as NSString).utf8String, -1, nil)

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
        // Check if uncompressed database exists in Documents directory
        let documentsPath = getDocumentsDirectory()
        let uncompressedDbPath = documentsPath.appendingPathComponent("dictionary.db").path

        // If uncompressed file exists, use it
        if FileManager.default.fileExists(atPath: uncompressedDbPath) {
            return uncompressedDbPath
        }

        // Otherwise, decompress from bundle
        guard let compressedDbPath = Bundle.main.path(forResource: "dictionary.db", ofType: "lzfse") else {
            print("Error: dictionary.db.lzfse not found in bundle")
            return nil
        }

        // Decompress the file
        if decompressDatabase(from: compressedDbPath, to: uncompressedDbPath) {
            return uncompressedDbPath
        }

        return nil
    }

    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func decompressDatabase(from sourcePath: String, to destinationPath: String) -> Bool {
        do {
            // Read the compressed data
            let compressedData = try Data(contentsOf: URL(fileURLWithPath: sourcePath))

            // Decompress using LZFSE
            guard let decompressedData = compressedData.withUnsafeBytes({ (bytes: UnsafeRawBufferPointer) -> Data? in
                guard let baseAddress = bytes.baseAddress else { return nil }

                // Create output buffer (estimate 10x compression ratio)
                let outputBufferSize = compressedData.count * 10
                var outputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: outputBufferSize)
                defer { outputBuffer.deallocate() }

                let decompressedSize = compression_decode_buffer(
                    outputBuffer,
                    outputBufferSize,
                    baseAddress.assumingMemoryBound(to: UInt8.self),
                    compressedData.count,
                    nil,
                    COMPRESSION_LZFSE
                )

                guard decompressedSize > 0 else { return nil }

                return Data(bytes: outputBuffer, count: decompressedSize)
            }) else {
                print("Error: Failed to decompress LZFSE data")
                return false
            }

            // Write the decompressed data to the destination
            try decompressedData.write(to: URL(fileURLWithPath: destinationPath))

            print("Successfully decompressed dictionary.db to \(destinationPath)")
            return true
        } catch {
            print("Error during decompression: \(error.localizedDescription)")
            return false
        }
    }
}

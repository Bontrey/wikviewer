import Foundation

class ODRManager: ObservableObject {
    @Published var downloadProgress: Double = 0.0
    @Published var isDownloaded: Bool = false
    @Published var isDownloading: Bool = false
    @Published var error: Error?

    private var resourceRequest: NSBundleResourceRequest?

    func checkIfDownloaded() {
        // Check if dictionary.db is available in the bundle (Debug/Simulator builds)
        if findDictionaryDatabase() != nil {
            DispatchQueue.main.async {
                self.isDownloaded = true
            }
            return
        }

        let tags = Set(["fr"])
        let request = NSBundleResourceRequest(tags: tags)

        request.conditionallyBeginAccessingResources { [weak self] resourcesAvailable in
            DispatchQueue.main.async {
                self?.isDownloaded = resourcesAvailable
                if resourcesAvailable {
                    self?.resourceRequest = request
                }
            }
        }
    }

    func downloadResources() {
        guard !isDownloading else { return }

        // Check if dictionary.db is available in the bundle (Debug/Simulator builds)
        if findDictionaryDatabase() != nil {
            DispatchQueue.main.async {
                self.isDownloaded = true
                self.downloadProgress = 1.0
            }
            return
        }

        let tags = Set(["fr"])
        let request = NSBundleResourceRequest(tags: tags)
        self.resourceRequest = request

        isDownloading = true
        error = nil

        request.beginAccessingResources { [weak self] error in
            DispatchQueue.main.async {
                self?.isDownloading = false

                if let error = error {
                    self?.error = error
                    self?.isDownloaded = false
                } else {
                    self?.isDownloaded = true
                    self?.downloadProgress = 1.0
                }
            }
        }

        // Monitor progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, self.isDownloading else {
                timer.invalidate()
                return
            }

            DispatchQueue.main.async {
                self.downloadProgress = self.resourceRequest?.progress.fractionCompleted ?? 0.0
            }
        }
    }

    private func findDictionaryDatabase() -> String? {
        // First try standard bundle location
        if let path = Bundle.main.path(forResource: "dictionary", ofType: "db") {
            return path
        }

        // Check in OnDemandResources directory (for embedded asset packs in Debug builds)
        let bundlePath = Bundle.main.bundlePath
        let odrPath = (bundlePath as NSString).appendingPathComponent("OnDemandResources")
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: odrPath) {
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: odrPath)
                for assetPack in contents {
                    let assetPackPath = (odrPath as NSString).appendingPathComponent(assetPack)
                    let dbPath = (assetPackPath as NSString).appendingPathComponent("dictionary.db")
                    if fileManager.fileExists(atPath: dbPath) {
                        return dbPath
                    }
                }
            } catch {
                print("Error searching OnDemandResources: \(error)")
            }
        }

        return nil
    }

    func endAccess() {
        resourceRequest?.endAccessingResources()
        resourceRequest = nil
    }

    deinit {
        endAccess()
    }
}

import SwiftUI

@main
struct MyAppApp: App {
    @StateObject private var odrManager = ODRManager()
    @StateObject private var databaseManager = DatabaseManager()

    var body: some Scene {
        WindowGroup {
            if odrManager.isDownloaded && !databaseManager.entries.isEmpty {
                ContentView(databaseManager: databaseManager)
            } else {
                DownloadView(odrManager: odrManager, databaseManager: databaseManager)
                    .onAppear {
                        odrManager.checkIfDownloaded()
                    }
            }
        }
    }
}

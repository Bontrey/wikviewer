import SwiftUI

struct DownloadView: View {
    @ObservedObject var odrManager: ODRManager
    @ObservedObject var databaseManager: DatabaseManager

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "book.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("French Dictionary")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Download the French dictionary database to get started")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if odrManager.isDownloading {
                VStack(spacing: 15) {
                    ProgressView(value: odrManager.downloadProgress) {
                        Text("Downloading...")
                    }
                    .progressViewStyle(.linear)
                    .frame(width: 250)

                    Text("\(Int(odrManager.downloadProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let error = odrManager.error {
                VStack(spacing: 15) {
                    Text("Download Failed")
                        .font(.headline)
                        .foregroundColor(.red)

                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("Retry") {
                        odrManager.downloadResources()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Button {
                    odrManager.downloadResources()
                } label: {
                    Label("Download Dictionary", systemImage: "arrow.down.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
        .onChange(of: odrManager.isDownloaded) { _, isDownloaded in
            if isDownloaded {
                // Load the dictionary from database
                databaseManager.loadDictionary()
            }
        }
    }
}

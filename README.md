# WikViewer

A Wiktionary iOS application built with SwiftUI featuring On-Demand Resources for efficient database delivery and a searchable dictionary interface.

## Features

- **On-Demand Resource Download**: Downloads the Wiktionary database only when needed, reducing initial app size
- **Full-Text Search**: SQLite FTS5-powered search with real-time filtering
- **Comprehensive Entries**: View words with definitions, glosses, examples, etymology, and part of speech
- **Clean SwiftUI Interface**: Modern master-detail navigation with search functionality
- **Universal App**: Supports both iPhone and iPad

## Project Structure

- `WikViewerApp.swift` - Main app entry point, manages ODR and database state
- `DownloadView.swift` - Initial view for downloading the Wiktionary database
- `ContentView.swift` - Search and list view with NavigationStack
- `DetailView.swift` - Detailed word entry view with sectioned layout
- `DictionaryEntry.swift` - Data model for dictionary entries
- `ODRManager.swift` - Manages On-Demand Resource downloads with progress tracking
- `DatabaseManager.swift` - Handles SQLite database operations
- `Info.plist` - App configuration (custom, not auto-generated)
- `dictionary.db` - Wiktionary database (ODR tagged with "fr")

## How to Run

### Using Xcode

1. Open the project:
   ```bash
   open WikViewer.xcodeproj
   ```

2. Select a simulator or connected device (iOS 17.0+)

3. Press Run (Cmd+R)

### Using Command Line

```bash
# List available simulators
xcrun simctl list devices available

# Build and run
xcodebuild -project WikViewer.xcodeproj \
  -scheme WikViewer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  run

# Or manually install and launch
xcrun simctl boot "iPhone 17"
open -a Simulator
xcodebuild -project WikViewer.xcodeproj \
  -scheme WikViewer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
xcrun simctl install booted "build/Build/Products/Debug-iphonesimulator/Wiktionary Viewer.app"
xcrun simctl launch booted com.example.WikViewer
```

## Requirements

- **Xcode**: 15.0 or later
- **iOS**: 17.0 or later
- **Swift**: 5.0
- **Platform**: iPhone and iPad (universal)

## Architecture

The app uses a standard SwiftUI master-detail pattern with On-Demand Resources:

1. **Download Phase**: `DownloadView` downloads the dictionary database via ODR
2. **Search Phase**: `ContentView` provides searchable list of dictionary entries
3. **Detail Phase**: `DetailView` displays complete entry information

### Data Model

Dictionary entries include:
- Word and part of speech
- Gloss (short definition)
- Full definition
- Usage examples
- Etymology

### On-Demand Resources

The Wiktionary database is delivered as an On-Demand Resource:
- Reduces initial app download size
- Downloads on first launch with progress tracking
- Database includes FTS5 full-text search support
- Tagged with "fr" for resource management

## Development

- SwiftUI Previews enabled for rapid iteration
- Automatic code signing
- Parallel builds enabled
- Debug builds embed asset packs for simulator testing

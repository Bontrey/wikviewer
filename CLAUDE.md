# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WikViewer (Wiktionary Viewer) is a Wiktionary iOS application built with SwiftUI. It features an embedded Wiktionary database with a searchable list of dictionary entries and detailed views for each word, including definitions, glosses, examples, and etymology.

## Build and Run

### Using Xcode
```bash
# Open project in Xcode
open WikViewer.xcodeproj

# Build from command line (use 'xcrun simctl list devices available' to see available simulators)
xcodebuild -project WikViewer.xcodeproj -scheme WikViewer -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run in simulator
xcodebuild -project WikViewer.xcodeproj -scheme WikViewer -destination 'platform=iOS Simulator,name=iPhone 17' run
```

### Simulator Commands
```bash
# List available simulators
xcrun simctl list devices available

# Boot a specific simulator
xcrun simctl boot "iPhone 17"

# Install and run the app
xcrun simctl install booted "build/Build/Products/Debug-iphonesimulator/Wiktionary Viewer.app"
xcrun simctl launch booted com.example.WikViewer

# Open Simulator.app
open -a Simulator
```

## Project Configuration

- **Target iOS Version**: iOS 18.0+
- **Xcode Version**: 15.0+
- **Swift Version**: 5.0
- **Bundle Identifier**: com.example.WikViewer
- **Product Name**: Wiktionary Viewer
- **Deployment Target**: iPhone and iPad (universal)

## Architecture

### App Structure
The app follows a standard SwiftUI master-detail architecture:

- **WikViewerApp.swift**: Entry point using the `@main` attribute with a `WindowGroup` scene containing the root view, initializes database on launch
- **ContentView.swift**: Main search and list view with `NavigationStack` and searchable modifier
- **DetailView.swift**: Detail view showing complete dictionary entry information
- **DictionaryEntry.swift**: Data model for dictionary entries
- **DatabaseManager.swift**: Handles SQLite database operations and entry loading from embedded dictionary.db file

### Data Model
`DictionaryEntry` is an `Identifiable` struct with the following properties:
- `id`: Unique UUID identifier
- `word`: The dictionary word
- `gloss`: Short definition (shown in list view)
- `partOfSpeech`: Grammatical category (noun, verb, adjective, etc.)
- `definition`: Full definition
- `examples`: Array of usage examples
- `etymology`: Optional word origin

The model includes `sampleData` with 10 pre-populated dictionary entries for testing.

### UI Components

**ContentView**:
- Uses `NavigationStack` for navigation hierarchy
- `searchable` modifier for real-time search functionality
- `List` with `NavigationLink` for each entry
- Search filters on word, gloss, and definition fields (case-insensitive)
- Each list item displays word (headline) and gloss (subheadline)

**DetailView**:
- `ScrollView` for scrollable content
- Sectioned layout with clear typography hierarchy
- Displays: word, part of speech, gloss, definition, examples, and etymology
- Uses uppercase caption labels for section headers

### Info.plist Configuration
The project uses a custom Info.plist (not auto-generated) located at `WikViewer/Info.plist`. This is explicitly configured in the build settings with `GENERATE_INFOPLIST_FILE = NO`.

## Development Notes

- SwiftUI Previews are enabled (`ENABLE_PREVIEWS = YES`) for rapid UI iteration
- Code signing is set to Automatic with no specific development team configured
- The build system uses parallel builds (`BuildIndependentTargetsInParallel = 1`)
- User script sandboxing is enabled for security

### Database

The app includes an embedded Wiktionary database:
- Dictionary database (dictionary.db) is embedded directly in the app bundle
- DatabaseManager loads entries from the SQLite database on app launch
- Database includes FTS5 full-text search support for fast word lookups

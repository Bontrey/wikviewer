# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MyApp is a dictionary iOS application built with SwiftUI. It features a searchable list of dictionary entries with detailed views for each word, including definitions, glosses, examples, and etymology.

## Build and Run

### Using Xcode
```bash
# Open project in Xcode
open MyApp.xcodeproj

# Build from command line (use 'xcrun simctl list devices available' to see available simulators)
xcodebuild -project MyApp.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run in simulator
xcodebuild -project MyApp.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17' run
```

### Simulator Commands
```bash
# List available simulators
xcrun simctl list devices available

# Boot a specific simulator
xcrun simctl boot "iPhone 17"

# Install and run the app
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/MyApp.app
xcrun simctl launch booted com.example.MyApp

# Open Simulator.app
open -a Simulator
```

## Project Configuration

- **Target iOS Version**: iOS 17.0+
- **Xcode Version**: 15.0+
- **Swift Version**: 5.0
- **Bundle Identifier**: com.example.MyApp
- **Product Name**: MyApp
- **Deployment Target**: iPhone and iPad (universal)

## Architecture

### App Structure
The app follows a standard SwiftUI master-detail architecture:

- **MyAppApp.swift**: Entry point using the `@main` attribute with a `WindowGroup` scene containing the root view
- **ContentView.swift**: Main search and list view with `NavigationStack` and searchable modifier
- **DetailView.swift**: Detail view showing complete dictionary entry information
- **DictionaryEntry.swift**: Data model and sample data for dictionary entries

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
The project uses a custom Info.plist (not auto-generated) located at `MyApp/Info.plist`. This is explicitly configured in the build settings with `GENERATE_INFOPLIST_FILE = NO`.

## Development Notes

- SwiftUI Previews are enabled (`ENABLE_PREVIEWS = YES`) for rapid UI iteration
- Code signing is set to Automatic with no specific development team configured
- The build system uses parallel builds (`BuildIndependentTargetsInParallel = 1`)
- User script sandboxing is enabled for security

### Future Enhancements

The app currently uses in-memory sample data for dictionary entries. Plans include:
- Migrating to SQLite database for persistent storage
- Implementing full-text search (FTS5) for more powerful search capabilities
- Loading dictionary data from external sources

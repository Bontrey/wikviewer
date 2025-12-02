# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MyApp is a minimal iOS application built with SwiftUI that displays a blue circle on a white screen. The app serves as a basic template for iOS development.

## Build and Run

### Using Xcode
```bash
# Open project in Xcode
open MyApp.xcodeproj

# Build from command line
xcodebuild -project MyApp.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run in simulator
xcodebuild -project MyApp.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15' run
```

### Simulator Commands
```bash
# List available simulators
xcrun simctl list devices available

# Boot a specific simulator
xcrun simctl boot "iPhone 15"

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
The app follows a standard SwiftUI architecture:

- **MyAppApp.swift**: Entry point using the `@main` attribute with a `WindowGroup` scene containing the root view
- **ContentView.swift**: Main view that composes a `ZStack` with a white background and blue circle overlay

### UI Components
The app uses SwiftUI's declarative syntax with:
- `ZStack` for layering views
- `Color.white.ignoresSafeArea()` for full-screen white background
- `Circle().fill(Color.blue)` with fixed 200x200 frame for the blue circle shape

### Info.plist Configuration
The project uses a custom Info.plist (not auto-generated) located at `MyApp/Info.plist`. This is explicitly configured in the build settings with `GENERATE_INFOPLIST_FILE = NO`.

## Development Notes

- SwiftUI Previews are enabled (`ENABLE_PREVIEWS = YES`) for rapid UI iteration
- Code signing is set to Automatic with no specific development team configured
- The build system uses parallel builds (`BuildIndependentTargetsInParallel = 1`)
- User script sandboxing is enabled for security

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**MixedOverlay3** is a SwiftUI iOS application for iOS 16+ targeting both iPhone and iPad devices. It's a fresh project with a minimal starter template consisting of an app entry point and main content view.

## Build and Development Commands

### Finding Available Simulators

Before building, list available iOS simulators:

```bash
xcodebuild -project MixedOverlay3.xcodeproj -scheme MixedOverlay3 -showdestinations
```

### Building the App

Build for the default simulator (ensure a simulator is available):

```bash
xcodebuild -project MixedOverlay3.xcodeproj -scheme MixedOverlay3 -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' build
```

Build with a specific simulator ID:

```bash
xcodebuild -project MixedOverlay3.xcodeproj -scheme MixedOverlay3 -destination 'platform=iOS Simulator,id=<SIMULATOR_ID>' build
```

### Cleaning Build Artifacts

```bash
xcodebuild -project MixedOverlay3.xcodeproj -scheme MixedOverlay3 clean
```

## Architecture and Code Organization

### Project Structure

- **MixedOverlay3App.swift**: Main app entry point with the @main App struct
- **ContentView.swift**: Primary UI view for the application
- **Assets.xcassets**: Image and color assets

The project uses file system synchronization in Xcode, meaning new Swift files added to the `MixedOverlay3/` directory are automatically included in the build without manual project configuration.

### SwiftUI and Modern Swift Patterns

#### State Management
- Uses SwiftUI's Observation framework with @Observable macro (not legacy @State/@StateObject)
- Prefer value types and local state to minimize global mutable state
- Avoid @Published and ObservableObject in favor of @Observable
- Example:
  ```swift
  @Observable
  final class ViewModel {
      var count = 0
  }
  ```

#### Concurrency
- **Swift 6 strict concurrency checking is enabled** via compiler settings
- Use `Task` and `async`/`await` instead of legacy `DispatchQueue`
- Use `@MainActor` to ensure UI updates run on main thread
- Use `Task.sleep(nanoseconds:)` for delays in concurrent contexts (NOT in unit tests)
- Use `withTaskGroup` for parallel work instead of `DispatchQueue.concurrentPerform`
- Never use `DispatchQueue` unless interoperating with legacy APIs

#### Optionals and Safety
- **NEVER use force unwraps (!)** or explicitly unwrapped optionals (!)
- Use safe unwrapping: `guard let`, `if let`, `??` operator
- Use `try` for throwing operations (never `try!`)
- This applies to all code including tests and previews

#### Dependency Injection and Testing
- Define all services with external dependencies as protocols
- Inject dependencies into view models and services
- This enables mock implementations for unit testing
- Example pattern:
  ```swift
  protocol DataServiceProtocol {
      func fetchData() async throws -> [Item]
  }

  @Observable
  final class ViewModel {
      private let dataService: DataServiceProtocol
      init(dataService: DataServiceProtocol = DataService()) {
          self.dataService = dataService
      }
  }
  ```

#### Logging
- Use `import OSLog` with the Logger type for structured logging
- Never use raw `print()` for debugging or logging
- Define a Logger utility with subsystem identifier
- Use Logger.debug() for development troubleshooting
- Logs are viewable in Console.app

### Build Configuration Details

- **iOS Deployment Target**: 16.0
- **Swift Version**: 5.0
- **Default Actor Isolation**: MainActor (UI-focused app)
- **Concurrency Settings**:
  - `SWIFT_APPROACHABLE_CONCURRENCY = YES`
  - `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
  - `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`
- **String Catalogs**: Enabled for localization via `STRING_CATALOG_GENERATE_SYMBOLS`
- **Previews**: Enabled for SwiftUI development

## Key Project Decisions

### No Test Target
This project does not include a dedicated test target. If unit tests are added, ensure they follow:
- Use protocol-based mocks for dependencies
- Never use sleep/Task.sleep in tests
- Mock implementations should replicate production behavior exactly
- Tests should compile and run without errors before committing

### Minimal External Dependencies
The project starts with no third-party dependencies. Any additions should be evaluated for necessity and integration with Swift 6 concurrency patterns.

### UI Framework
SwiftUI is the sole UI framework. No UIKit views.

## Development Workflow

When adding new features:
1. Create new Swift files in `MixedOverlay3/` directory (automatically included)
2. Use value types and @Observable for state
3. Inject external dependencies as protocol types
4. Ensure all code uses `async`/`await` and avoids DispatchQueue
5. Build and verify compilation with xcodebuild before committing
6. Keep code simple—avoid premature abstractions

## Git and Version Control

- Minimum deployment target and build settings should not be changed without consideration
- Development Team ID is M8T74C3QWG (keep this for build signing)
- Product bundle identifier is `functioncraft.MixedOverlay3`

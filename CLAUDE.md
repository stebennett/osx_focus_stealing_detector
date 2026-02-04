# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

All commands should be run from the `FocusStealer/` directory:

```bash
cd FocusStealer

# Build (debug)
swift build

# Build (release) - outputs to .build/release/FocusStealer
swift build -c release

# Run the app
swift run FocusStealer

# Run tests (custom test runner, not XCTest)
swift run FocusStealerTests
```

## Architecture

FocusStealer is a macOS menu bar app that tracks application focus changes. It uses an event-driven architecture (no polling) via NSWorkspace notifications.

```
FocusStealerApp (@main)
├── AppDelegate - lifecycle management
│   ├── FocusWatcher - listens to NSWorkspace.didActivateApplicationNotification
│   └── FocusStore - tracks history, calculates durations, persists to JSON
└── MenuBarExtra - SwiftUI dropdown showing current app + recent history
```

**Key architectural decisions:**
- **Two targets**: `FocusStealer` (executable) and `FocusStealerLib` (library with reusable models)
- **@MainActor**: FocusStore uses @MainActor for thread-safe UI updates
- **Combine framework**: FocusWatcher uses reactive subscriptions for NSWorkspace events
- **Daily JSON files**: History persisted to `~/.focus-stealer/YYYY-MM-DD.json`

**Source layout:**
- `Sources/FocusStealer/` - App entry point, MenuBarView, FocusWatcher
- `Sources/FocusStealerLib/` - FocusEvent model, FocusStore, Formatters
- `Tests/FocusStealerTests/` - Custom test runner (executable target, not XCTest)

## Testing

Tests use a custom runner (not XCTest) defined as an executable target. Run with:

```bash
swift run FocusStealerTests
```

The test runner prints pass/fail for each test and exits with code 1 on any failure.

## Data Storage

Focus history is saved to `~/.focus-stealer/` with one JSON file per day. Each file contains an array of FocusEvent objects with ISO8601 timestamps.

## Legacy Python Tool

The original Python CLI (`focus_stealer.py`) is still in the repo root. Run with `uv run focus-stealer` (requires `uv sync` first).

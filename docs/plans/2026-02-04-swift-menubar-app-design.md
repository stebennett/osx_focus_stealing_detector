# FocusStealer: Swift Menu Bar App Design

## Overview

A native macOS menu bar app that tracks application focus changes. Shows the currently focused app in the menu bar. Click to see recent focus history with timestamps and durations.

**Goals:**
1. Catch focus stealers - identify which apps grab focus unexpectedly
2. Track focus patterns - understand time spent across apps

## Architecture

A single-process SwiftUI app with three components:

```
┌─────────────────────────────────────────────────┐
│                  FocusStealer.app               │
├─────────────────────────────────────────────────┤
│  FocusWatcher      FocusStore      MenuBarView  │
│  (notifications)   (history)       (UI)         │
│       │                │                │       │
│       └───────> updates <───────────────┘       │
└─────────────────────────────────────────────────┘
         │
         v
   ~/.focus-stealer/YYYY-MM-DD.json
```

## Components

### FocusWatcher

Listens for focus changes using macOS notifications:

```swift
NotificationCenter.default.addObserver(
    forName: NSWorkspace.didActivateApplicationNotification,
    object: nil,
    queue: .main
) { notification in
    let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
    // Update store
}
```

**Captures per event:**
- App name (localized)
- Bundle ID (stable identifier)
- Timestamp

**Benefits over polling:**
- Zero CPU while idle
- Instant detection
- Battery friendly

### FocusStore

Manages history in memory, persists to disk.

**Data model:**
```swift
struct FocusEvent: Codable {
    let appName: String
    let bundleId: String
    let startTime: Date
    var duration: TimeInterval
}
```

**State:**
- `currentApp` - Currently focused app (for menu bar display)
- `todayHistory` - Array of FocusEvents

**Duration calculation:**
When app B gains focus, finalize app A's duration as `now - A.startTime`.

**Persistence:**
- Path: `~/.focus-stealer/YYYY-MM-DD.json`
- Auto-save on focus change (debounced)
- Load today's file on launch
- Old files remain on disk for manual review

### MenuBarView

SwiftUI `MenuBarExtra` showing:

**Menu bar:** Current app name (e.g., `Safari`)

**Dropdown:**
```
── Currently Focused ──
Safari                           now

── Recent (today) ──
iTerm2                    2:31pm · 12m 20s
Slack                     2:18pm · 13m 05s
Safari                    2:10pm · 8m 12s
...

──────────────
Quit FocusStealer
```

**Details:**
- Last ~20 entries, most recent first
- Duration format: `45s`, `3m 20s`, `1h 5m`
- Current app shows "now" (duration still accumulating)

## Error Handling

**File system:**
- Create `~/.focus-stealer/` on first run if missing
- Corrupted JSON: log warning, start fresh
- Write failure: continue with in-memory only

**App lifecycle:**
- On quit: finalize current duration, save
- On launch: load today's history, resume tracking

**Edge cases:**
- Screen locked: record events normally (often "loginwindow")
- No focused app: show "None"
- Same app refocused: ignore (no duplicate entries)

## Requirements

- macOS 13+ (Ventura) - required for SwiftUI `MenuBarExtra`
- Xcode 14+

## Future Possibilities (not in scope)

- View past days' history
- Daily/weekly summaries
- Preferences window
- Login item configuration UI
- Notifications for specific "focus stealer" apps

## File Structure

```
FocusStealer/
├── FocusStealer.xcodeproj
├── FocusStealer/
│   ├── FocusStealerApp.swift      # App entry point, MenuBarExtra
│   ├── FocusWatcher.swift         # NSWorkspace notification observer
│   ├── FocusStore.swift           # History management, persistence
│   ├── FocusEvent.swift           # Data model
│   ├── MenuBarView.swift          # Dropdown UI
│   └── Formatters.swift           # Duration/time formatting helpers
└── README.md
```

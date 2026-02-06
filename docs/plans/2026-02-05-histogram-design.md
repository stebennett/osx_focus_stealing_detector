# Today's Usage Histogram Design

## Overview

Add a histogram section to the menu bar dropdown showing time spent per app today.

## Requirements

- **Time range**: Today only (resets at midnight)
- **Visualization**: Horizontal bars showing total time per app
- **Apps shown**: Top 5 apps + "Other" bucket aggregating the rest
- **Labels**: App name, proportional bar, duration (e.g., `Safari [████████] 2h 15m`)
- **Placement**: Between "Currently Focused" and "Recent" sections
- **History limit**: Reduce from 20 to 10 items

## Data Model

Add computed property to `FocusStore`:

```swift
public var todayTimeByApp: [(appName: String, duration: TimeInterval)] {
    // Group history by appName, sum durations
    // Sort by duration descending
    // Return top 5 + aggregate "Other" (if any remaining)
}
```

No changes to `FocusEvent` or storage format.

## View Component

New `HistogramView` struct:

```swift
struct HistogramView: View {
    let items: [(appName: String, duration: TimeInterval)]

    // Each row:
    // - App name (left, ~80px, truncate with ellipsis)
    // - Horizontal bar (flexible, proportional to max duration)
    // - Duration label (right, ~60px)
}
```

Bar width calculated relative to the longest bar (top app fills available width).

## Layout

```
┌─────────────────────────────────┐
│ Currently Focused               │
│ Safari                     now  │
├─────────────────────────────────┤
│ Today's Usage                   │  ← NEW SECTION
│ Safari      [████████]  2h 15m  │
│ VS Code     [██████]    1h 30m  │
│ Terminal    [███]         45m   │
│ Slack       [██]          30m   │
│ Mail        [█]           15m   │
│ Other       [█]           20m   │
├─────────────────────────────────┤
│ Recent (today)                  │
│ Safari         2:15pm · 5m 30s  │
│ (10 items max)                  │
├─────────────────────────────────┤
│ Quit FocusStealer               │
└─────────────────────────────────┘
```

## Edge Cases

- **Empty state**: Show "No usage data yet" if no history exists
- **Single app**: Show only that app (no "Other" row)
- **Short durations**: Filter out apps with <1 second total
- **Current app**: Not included until user switches away (consistent with existing behavior)

## Files to Change

1. `FocusStore.swift` - Add `todayTimeByApp` computed property
2. `MenuBarView.swift` - Add `HistogramView`, integrate into main view, change `prefix(20)` to `prefix(10)`

## Files Unchanged

- `FocusEvent.swift`
- `FocusWatcher.swift`
- `Formatters.swift` (reuses existing `formatDuration()`)

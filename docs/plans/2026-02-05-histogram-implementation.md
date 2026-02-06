# Today's Usage Histogram Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a "Today's Usage" histogram section to the menu bar dropdown showing time spent per app with horizontal bars.

**Architecture:** Add a computed property `todayTimeByApp` to `FocusStore` that aggregates history by app name. Create a new `HistogramView` SwiftUI component and integrate it into `MenuBarView` between the current app section and history.

**Tech Stack:** Swift, SwiftUI, Combine

---

### Task 1: Add `todayTimeByApp` computed property to FocusStore

**Files:**
- Modify: `Sources/FocusStealerLib/FocusStore.swift`
- Test: `Tests/FocusStealerTests/FocusStoreTests.swift`

**Step 1: Write the failing test**

Add to `Tests/FocusStealerTests/FocusStoreTests.swift`:

```swift
func testTodayTimeByAppEmpty() throws {
    let store = FocusStore(storageDirectory: tempDir)
    let result = store.todayTimeByApp

    assert(result.isEmpty, "Expected empty result for empty history")
    print("  PASSED: testTodayTimeByAppEmpty")
}
```

Register the test in `runAllTests()`:

```swift
testTodayTimeByAppEmpty()
```

**Step 2: Run test to verify it fails**

Run: `swift run FocusStealerTests`
Expected: Compiler error - `todayTimeByApp` does not exist

**Step 3: Write minimal implementation**

Add to `Sources/FocusStealerLib/FocusStore.swift` after the `history` property:

```swift
public var todayTimeByApp: [(appName: String, duration: TimeInterval)] {
    return []
}
```

**Step 4: Run test to verify it passes**

Run: `swift run FocusStealerTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/FocusStealerLib/FocusStore.swift Tests/FocusStealerTests/FocusStoreTests.swift
git commit -m "feat(store): add empty todayTimeByApp computed property"
```

---

### Task 2: Implement aggregation logic for todayTimeByApp

**Files:**
- Modify: `Sources/FocusStealerLib/FocusStore.swift`
- Modify: `Tests/FocusStealerTests/FocusStoreTests.swift`

**Step 1: Write the failing test**

Add to `Tests/FocusStealerTests/FocusStoreTests.swift`:

```swift
func testTodayTimeByAppAggregation() throws {
    let store = FocusStore(storageDirectory: tempDir)

    // Simulate focus changes to build history
    store.recordFocusChange(appName: "Safari", bundleId: "com.apple.Safari")
    Thread.sleep(forTimeInterval: 0.1)
    store.recordFocusChange(appName: "VS Code", bundleId: "com.microsoft.VSCode")
    Thread.sleep(forTimeInterval: 0.2)
    store.recordFocusChange(appName: "Safari", bundleId: "com.apple.Safari")
    Thread.sleep(forTimeInterval: 0.1)
    store.recordFocusChange(appName: "Terminal", bundleId: "com.apple.Terminal")

    let result = store.todayTimeByApp

    // Safari should be first (0.1 + 0.1 = ~0.2s total)
    // VS Code should be second (~0.2s)
    assert(result.count == 2, "Expected 2 apps, got \(result.count)")
    assert(result[0].appName == "Safari", "Expected Safari first, got \(result[0].appName)")
    assert(result[1].appName == "VS Code", "Expected VS Code second, got \(result[1].appName)")
    assert(result[0].duration > result[1].duration, "Safari should have more time than VS Code")

    print("  PASSED: testTodayTimeByAppAggregation")
}
```

Register the test in `runAllTests()`:

```swift
testTodayTimeByAppAggregation()
```

**Step 2: Run test to verify it fails**

Run: `swift run FocusStealerTests`
Expected: FAIL - assertion fails because todayTimeByApp returns empty

**Step 3: Write implementation**

Replace the `todayTimeByApp` property in `Sources/FocusStealerLib/FocusStore.swift`:

```swift
public var todayTimeByApp: [(appName: String, duration: TimeInterval)] {
    // Group by app name and sum durations
    var timeByApp: [String: TimeInterval] = [:]
    for event in history {
        timeByApp[event.appName, default: 0] += event.duration
    }

    // Filter out very short durations (<1 second)
    let filtered = timeByApp.filter { $0.value >= 1.0 }

    // Sort by duration descending
    let sorted = filtered.sorted { $0.value > $1.value }

    return sorted.map { (appName: $0.key, duration: $0.value) }
}
```

**Step 4: Run test to verify it passes**

Run: `swift run FocusStealerTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/FocusStealerLib/FocusStore.swift Tests/FocusStealerTests/FocusStoreTests.swift
git commit -m "feat(store): implement todayTimeByApp aggregation logic"
```

---

### Task 3: Add top 5 + Other bucketing

**Files:**
- Modify: `Sources/FocusStealerLib/FocusStore.swift`
- Modify: `Tests/FocusStealerTests/FocusStoreTests.swift`

**Step 1: Write the failing test**

Add to `Tests/FocusStealerTests/FocusStoreTests.swift`:

```swift
func testTodayTimeByAppTop5PlusOther() throws {
    let store = FocusStore(storageDirectory: tempDir)

    // Create 7 apps with different durations
    let apps = [
        ("App1", "com.test.app1", 7.0),
        ("App2", "com.test.app2", 6.0),
        ("App3", "com.test.app3", 5.0),
        ("App4", "com.test.app4", 4.0),
        ("App5", "com.test.app5", 3.0),
        ("App6", "com.test.app6", 2.0),
        ("App7", "com.test.app7", 1.0),
    ]

    // Simulate focus changes with sleep to create durations
    for (name, bundleId, duration) in apps {
        store.recordFocusChange(appName: name, bundleId: bundleId)
        Thread.sleep(forTimeInterval: duration)
    }
    // Final switch to finalize last app
    store.recordFocusChange(appName: "Final", bundleId: "com.test.final")

    let result = store.todayTimeByApp

    // Should have top 5 + Other = 6 entries
    assert(result.count == 6, "Expected 6 entries (top 5 + Other), got \(result.count)")
    assert(result[0].appName == "App1", "Expected App1 first")
    assert(result[1].appName == "App2", "Expected App2 second")
    assert(result[2].appName == "App3", "Expected App3 third")
    assert(result[3].appName == "App4", "Expected App4 fourth")
    assert(result[4].appName == "App5", "Expected App5 fifth")
    assert(result[5].appName == "Other", "Expected Other last, got \(result[5].appName)")

    // Other should have App6 + App7 durations (~3s)
    assert(result[5].duration >= 2.5 && result[5].duration <= 3.5,
           "Other duration should be ~3s, got \(result[5].duration)")

    print("  PASSED: testTodayTimeByAppTop5PlusOther")
}
```

Register the test in `runAllTests()`:

```swift
testTodayTimeByAppTop5PlusOther()
```

**Step 2: Run test to verify it fails**

Run: `swift run FocusStealerTests`
Expected: FAIL - returns 7 entries, not 6 with "Other"

**Step 3: Write implementation**

Replace the `todayTimeByApp` property in `Sources/FocusStealerLib/FocusStore.swift`:

```swift
public var todayTimeByApp: [(appName: String, duration: TimeInterval)] {
    // Group by app name and sum durations
    var timeByApp: [String: TimeInterval] = [:]
    for event in history {
        timeByApp[event.appName, default: 0] += event.duration
    }

    // Filter out very short durations (<1 second)
    let filtered = timeByApp.filter { $0.value >= 1.0 }

    // Sort by duration descending
    let sorted = filtered.sorted { $0.value > $1.value }

    // Take top 5, bucket the rest as "Other"
    if sorted.count <= 5 {
        return sorted.map { (appName: $0.key, duration: $0.value) }
    }

    let top5 = sorted.prefix(5).map { (appName: $0.key, duration: $0.value) }
    let otherDuration = sorted.dropFirst(5).reduce(0.0) { $0 + $1.value }

    return top5 + [(appName: "Other", duration: otherDuration)]
}
```

**Step 4: Run test to verify it passes**

Run: `swift run FocusStealerTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/FocusStealerLib/FocusStore.swift Tests/FocusStealerTests/FocusStoreTests.swift
git commit -m "feat(store): add top 5 + Other bucketing to todayTimeByApp"
```

---

### Task 4: Create HistogramView component

**Files:**
- Create: `Sources/FocusStealer/HistogramView.swift`

**Step 1: Create the view file**

Create `Sources/FocusStealer/HistogramView.swift`:

```swift
import SwiftUI
import FocusStealerLib

struct HistogramView: View {
    let items: [(appName: String, duration: TimeInterval)]

    private var maxDuration: TimeInterval {
        items.map(\.duration).max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 8) {
                    // App name
                    Text(item.appName)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(width: 70, alignment: .leading)

                    // Bar
                    GeometryReader { geometry in
                        let barWidth = (item.duration / maxDuration) * geometry.size.width
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentColor)
                            .frame(width: max(barWidth, 4))
                    }
                    .frame(height: 12)

                    // Duration
                    Text(formatDuration(item.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 55, alignment: .trailing)
                }
                .frame(height: 20)
            }
        }
    }
}
```

**Step 2: Verify it compiles**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add Sources/FocusStealer/HistogramView.swift
git commit -m "feat(view): add HistogramView component"
```

---

### Task 5: Integrate histogram into MenuBarView

**Files:**
- Modify: `Sources/FocusStealer/MenuBarView.swift`

**Step 1: Add histogram section**

In `Sources/FocusStealer/MenuBarView.swift`, add after the first `Divider()` block (after the "Currently Focused" section):

```swift
// Today's usage histogram section
Section {
    if store.todayTimeByApp.isEmpty {
        Text("No usage data yet")
            .foregroundColor(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
    } else {
        HistogramView(items: store.todayTimeByApp)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
    }
} header: {
    Text("Today's Usage")
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
}

Divider()
    .padding(.vertical, 4)
```

**Step 2: Reduce history limit from 20 to 10**

In the same file, change:

```swift
ForEach(store.history.prefix(20)) { event in
```

to:

```swift
ForEach(store.history.prefix(10)) { event in
```

**Step 3: Verify it compiles and builds**

Run: `swift build`
Expected: Build succeeds

**Step 4: Commit**

```bash
git add Sources/FocusStealer/MenuBarView.swift
git commit -m "feat(view): integrate histogram into MenuBarView, reduce history to 10"
```

---

### Task 6: Manual testing and final verification

**Step 1: Run all tests**

Run: `swift run FocusStealerTests`
Expected: All tests pass

**Step 2: Build release version**

Run: `swift build -c release`
Expected: Build succeeds

**Step 3: Manual test**

Run: `swift run FocusStealer`

Verify:
1. Menu bar icon appears
2. Click to open dropdown
3. "Currently Focused" section shows current app
4. "Today's Usage" section appears (may show "No usage data yet" initially)
5. Switch between a few apps, then check dropdown again
6. Histogram should show bars with app names and durations
7. "Recent (today)" section shows last 10 events
8. Quit button works

**Step 4: Commit any fixes if needed**

If issues found, fix and commit.

**Step 5: Final commit message**

If all working, the feature is complete. No additional commit needed.

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 1 | Add empty todayTimeByApp property | FocusStore.swift, FocusStoreTests.swift |
| 2 | Implement aggregation logic | FocusStore.swift, FocusStoreTests.swift |
| 3 | Add top 5 + Other bucketing | FocusStore.swift, FocusStoreTests.swift |
| 4 | Create HistogramView component | HistogramView.swift |
| 5 | Integrate into MenuBarView | MenuBarView.swift |
| 6 | Manual testing and verification | - |

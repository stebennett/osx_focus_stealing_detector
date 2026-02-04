# FocusStealer Swift Menu Bar App Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a native macOS menu bar app that tracks application focus changes with timestamps and durations.

**Architecture:** Single-process SwiftUI app with FocusWatcher (listens to NSWorkspace notifications), FocusStore (manages history + persistence), and MenuBarView (SwiftUI MenuBarExtra UI).

**Tech Stack:** Swift 5.9+, SwiftUI, AppKit (NSWorkspace), macOS 13+ MenuBarExtra API

**Worktree:** `/Users/stevebennett/code/github/osx_focus_stealing_detector/.worktrees/swift-menubar`

---

## Task 1: Create Xcode Project

**Goal:** Set up the Xcode project structure for a menu bar app.

**Step 1: Create project using Xcode CLI**

Run from worktree root:
```bash
cd /Users/stevebennett/code/github/osx_focus_stealing_detector/.worktrees/swift-menubar
mkdir -p FocusStealer
```

**Step 2: Create the Xcode project file structure**

Since we're working from CLI, we'll create a Swift Package Manager-based app that Xcode can open. Create the project structure:

```
FocusStealer/
├── Package.swift
├── Sources/
│   └── FocusStealer/
│       └── FocusStealerApp.swift
└── Tests/
    └── FocusStealerTests/
        └── FocusStealerTests.swift
```

**Step 3: Create Package.swift**

Create: `FocusStealer/Package.swift`

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FocusStealer",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "FocusStealer",
            path: "Sources/FocusStealer"
        ),
        .testTarget(
            name: "FocusStealerTests",
            dependencies: ["FocusStealer"],
            path: "Tests/FocusStealerTests"
        )
    ]
)
```

**Step 4: Create minimal app entry point**

Create: `FocusStealer/Sources/FocusStealer/FocusStealerApp.swift`

```swift
import SwiftUI

@main
struct FocusStealerApp: App {
    var body: some Scene {
        MenuBarExtra("FocusStealer", systemImage: "eye") {
            Text("Hello, FocusStealer!")
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
```

**Step 5: Create placeholder test file**

Create: `FocusStealer/Tests/FocusStealerTests/FocusStealerTests.swift`

```swift
import XCTest

final class FocusStealerTests: XCTestCase {
    func testPlaceholder() {
        XCTAssertTrue(true)
    }
}
```

**Step 6: Build and verify**

Run:
```bash
cd FocusStealer && swift build
```
Expected: Build succeeds

**Step 7: Run tests**

Run:
```bash
swift test
```
Expected: 1 test passes

**Step 8: Commit**

```bash
git add FocusStealer/
git commit -m "feat: create Swift Package for FocusStealer menu bar app"
```

---

## Task 2: Create FocusEvent Data Model

**Goal:** Define the data structure for tracking focus events.

**Files:**
- Create: `FocusStealer/Sources/FocusStealer/FocusEvent.swift`
- Create: `FocusStealer/Tests/FocusStealerTests/FocusEventTests.swift`

**Step 1: Write the failing test**

Create: `FocusStealer/Tests/FocusStealerTests/FocusEventTests.swift`

```swift
import XCTest
@testable import FocusStealer

final class FocusEventTests: XCTestCase {
    func testFocusEventCreation() {
        let now = Date()
        let event = FocusEvent(
            appName: "Safari",
            bundleId: "com.apple.Safari",
            startTime: now,
            duration: 0
        )

        XCTAssertEqual(event.appName, "Safari")
        XCTAssertEqual(event.bundleId, "com.apple.Safari")
        XCTAssertEqual(event.startTime, now)
        XCTAssertEqual(event.duration, 0)
    }

    func testFocusEventEncodeDecode() throws {
        let now = Date()
        let event = FocusEvent(
            appName: "Safari",
            bundleId: "com.apple.Safari",
            startTime: now,
            duration: 120.5
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(event)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FocusEvent.self, from: data)

        XCTAssertEqual(decoded.appName, event.appName)
        XCTAssertEqual(decoded.bundleId, event.bundleId)
        XCTAssertEqual(decoded.duration, event.duration)
    }
}
```

**Step 2: Run test to verify it fails**

Run:
```bash
cd FocusStealer && swift test --filter FocusEventTests
```
Expected: FAIL - cannot find 'FocusEvent' in scope

**Step 3: Write the implementation**

Create: `FocusStealer/Sources/FocusStealer/FocusEvent.swift`

```swift
import Foundation

struct FocusEvent: Codable, Identifiable {
    let id: UUID
    let appName: String
    let bundleId: String
    let startTime: Date
    var duration: TimeInterval

    init(
        id: UUID = UUID(),
        appName: String,
        bundleId: String,
        startTime: Date,
        duration: TimeInterval = 0
    ) {
        self.id = id
        self.appName = appName
        self.bundleId = bundleId
        self.startTime = startTime
        self.duration = duration
    }
}
```

**Step 4: Run test to verify it passes**

Run:
```bash
cd FocusStealer && swift test --filter FocusEventTests
```
Expected: 2 tests pass

**Step 5: Commit**

```bash
git add FocusStealer/Sources/FocusStealer/FocusEvent.swift FocusStealer/Tests/FocusStealerTests/FocusEventTests.swift
git commit -m "feat: add FocusEvent data model with Codable support"
```

---

## Task 3: Create Duration and Time Formatters

**Goal:** Create helpers to format durations ("3m 20s") and times ("2:31pm").

**Files:**
- Create: `FocusStealer/Sources/FocusStealer/Formatters.swift`
- Create: `FocusStealer/Tests/FocusStealerTests/FormattersTests.swift`

**Step 1: Write the failing tests**

Create: `FocusStealer/Tests/FocusStealerTests/FormattersTests.swift`

```swift
import XCTest
@testable import FocusStealer

final class FormattersTests: XCTestCase {
    func testFormatDurationSeconds() {
        XCTAssertEqual(formatDuration(45), "45s")
    }

    func testFormatDurationMinutesAndSeconds() {
        XCTAssertEqual(formatDuration(200), "3m 20s")
    }

    func testFormatDurationHoursAndMinutes() {
        XCTAssertEqual(formatDuration(3900), "1h 5m")
    }

    func testFormatDurationZero() {
        XCTAssertEqual(formatDuration(0), "0s")
    }

    func testFormatTimeOfDay() {
        var components = DateComponents()
        components.year = 2026
        components.month = 2
        components.day = 4
        components.hour = 14
        components.minute = 31

        let calendar = Calendar.current
        let date = calendar.date(from: components)!

        let result = formatTimeOfDay(date)
        // Format depends on locale, but should contain 2:31 or 14:31
        XCTAssertTrue(result.contains("31"), "Expected time to contain minutes: \(result)")
    }
}
```

**Step 2: Run test to verify it fails**

Run:
```bash
cd FocusStealer && swift test --filter FormattersTests
```
Expected: FAIL - cannot find 'formatDuration' in scope

**Step 3: Write the implementation**

Create: `FocusStealer/Sources/FocusStealer/Formatters.swift`

```swift
import Foundation

func formatDuration(_ seconds: TimeInterval) -> String {
    let totalSeconds = Int(seconds)

    if totalSeconds < 60 {
        return "\(totalSeconds)s"
    }

    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let secs = totalSeconds % 60

    if hours > 0 {
        return "\(hours)h \(minutes)m"
    }

    return "\(minutes)m \(secs)s"
}

func formatTimeOfDay(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mma"
    return formatter.string(from: date).lowercased()
}
```

**Step 4: Run test to verify it passes**

Run:
```bash
cd FocusStealer && swift test --filter FormattersTests
```
Expected: 5 tests pass

**Step 5: Commit**

```bash
git add FocusStealer/Sources/FocusStealer/Formatters.swift FocusStealer/Tests/FocusStealerTests/FormattersTests.swift
git commit -m "feat: add duration and time formatters"
```

---

## Task 4: Create FocusStore (In-Memory)

**Goal:** Create the store that manages focus history in memory.

**Files:**
- Create: `FocusStealer/Sources/FocusStealer/FocusStore.swift`
- Create: `FocusStealer/Tests/FocusStealerTests/FocusStoreTests.swift`

**Step 1: Write the failing tests**

Create: `FocusStealer/Tests/FocusStealerTests/FocusStoreTests.swift`

```swift
import XCTest
@testable import FocusStealer

final class FocusStoreTests: XCTestCase {
    func testInitialState() {
        let store = FocusStore()
        XCTAssertNil(store.currentAppName)
        XCTAssertTrue(store.history.isEmpty)
    }

    func testRecordFocusChange() {
        let store = FocusStore()

        store.recordFocusChange(appName: "Safari", bundleId: "com.apple.Safari")

        XCTAssertEqual(store.currentAppName, "Safari")
        XCTAssertTrue(store.history.isEmpty) // First app has no completed event yet
    }

    func testRecordSecondFocusChangeCreatesHistory() {
        let store = FocusStore()

        store.recordFocusChange(appName: "Safari", bundleId: "com.apple.Safari")

        // Wait a tiny bit to ensure duration > 0
        Thread.sleep(forTimeInterval: 0.1)

        store.recordFocusChange(appName: "iTerm2", bundleId: "com.googlecode.iterm2")

        XCTAssertEqual(store.currentAppName, "iTerm2")
        XCTAssertEqual(store.history.count, 1)
        XCTAssertEqual(store.history.first?.appName, "Safari")
        XCTAssertGreaterThan(store.history.first?.duration ?? 0, 0)
    }

    func testIgnoreSameApp() {
        let store = FocusStore()

        store.recordFocusChange(appName: "Safari", bundleId: "com.apple.Safari")
        store.recordFocusChange(appName: "Safari", bundleId: "com.apple.Safari")

        XCTAssertEqual(store.currentAppName, "Safari")
        XCTAssertTrue(store.history.isEmpty) // No change recorded
    }
}
```

**Step 2: Run test to verify it fails**

Run:
```bash
cd FocusStealer && swift test --filter FocusStoreTests
```
Expected: FAIL - cannot find 'FocusStore' in scope

**Step 3: Write the implementation**

Create: `FocusStealer/Sources/FocusStealer/FocusStore.swift`

```swift
import Foundation
import SwiftUI

@MainActor
class FocusStore: ObservableObject {
    @Published private(set) var currentAppName: String?
    @Published private(set) var currentBundleId: String?
    @Published private(set) var history: [FocusEvent] = []

    private var currentEventStart: Date?

    func recordFocusChange(appName: String, bundleId: String) {
        // Ignore if same app
        if bundleId == currentBundleId {
            return
        }

        // Finalize previous app's event
        if let previousApp = currentAppName,
           let previousBundleId = currentBundleId,
           let startTime = currentEventStart {
            let duration = Date().timeIntervalSince(startTime)
            let event = FocusEvent(
                appName: previousApp,
                bundleId: previousBundleId,
                startTime: startTime,
                duration: duration
            )
            history.insert(event, at: 0) // Most recent first
        }

        // Start tracking new app
        currentAppName = appName
        currentBundleId = bundleId
        currentEventStart = Date()
    }

    func finalizeCurrentEvent() {
        // Called when app quits - finalize current app's duration
        if let appName = currentAppName,
           let bundleId = currentBundleId,
           let startTime = currentEventStart {
            let duration = Date().timeIntervalSince(startTime)
            let event = FocusEvent(
                appName: appName,
                bundleId: bundleId,
                startTime: startTime,
                duration: duration
            )
            history.insert(event, at: 0)
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run:
```bash
cd FocusStealer && swift test --filter FocusStoreTests
```
Expected: 4 tests pass

**Step 5: Commit**

```bash
git add FocusStealer/Sources/FocusStealer/FocusStore.swift FocusStealer/Tests/FocusStealerTests/FocusStoreTests.swift
git commit -m "feat: add FocusStore for in-memory history management"
```

---

## Task 5: Add Persistence to FocusStore

**Goal:** Add JSON file persistence to save/load daily history.

**Files:**
- Modify: `FocusStealer/Sources/FocusStealer/FocusStore.swift`
- Modify: `FocusStealer/Tests/FocusStealerTests/FocusStoreTests.swift`

**Step 1: Add persistence tests**

Add to `FocusStealer/Tests/FocusStealerTests/FocusStoreTests.swift`:

```swift
    func testSaveAndLoadHistory() throws {
        // Use a temp directory for testing
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FocusStealerTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let store = FocusStore(storageDirectory: tempDir)

        store.recordFocusChange(appName: "Safari", bundleId: "com.apple.Safari")
        Thread.sleep(forTimeInterval: 0.1)
        store.recordFocusChange(appName: "iTerm2", bundleId: "com.googlecode.iterm2")

        store.save()

        // Create new store and load
        let store2 = FocusStore(storageDirectory: tempDir)
        store2.load()

        XCTAssertEqual(store2.history.count, 1)
        XCTAssertEqual(store2.history.first?.appName, "Safari")
    }
```

**Step 2: Run test to verify it fails**

Run:
```bash
cd FocusStealer && swift test --filter FocusStoreTests
```
Expected: FAIL - initializer with storageDirectory not found

**Step 3: Update implementation with persistence**

Update `FocusStealer/Sources/FocusStealer/FocusStore.swift`:

```swift
import Foundation
import SwiftUI

@MainActor
class FocusStore: ObservableObject {
    @Published private(set) var currentAppName: String?
    @Published private(set) var currentBundleId: String?
    @Published private(set) var history: [FocusEvent] = []

    private var currentEventStart: Date?
    private let storageDirectory: URL

    init(storageDirectory: URL? = nil) {
        if let dir = storageDirectory {
            self.storageDirectory = dir
        } else {
            self.storageDirectory = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".focus-stealer")
        }
    }

    private var todayFilePath: URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filename = "\(formatter.string(from: Date())).json"
        return storageDirectory.appendingPathComponent(filename)
    }

    func recordFocusChange(appName: String, bundleId: String) {
        // Ignore if same app
        if bundleId == currentBundleId {
            return
        }

        // Finalize previous app's event
        if let previousApp = currentAppName,
           let previousBundleId = currentBundleId,
           let startTime = currentEventStart {
            let duration = Date().timeIntervalSince(startTime)
            let event = FocusEvent(
                appName: previousApp,
                bundleId: previousBundleId,
                startTime: startTime,
                duration: duration
            )
            history.insert(event, at: 0)
        }

        // Start tracking new app
        currentAppName = appName
        currentBundleId = bundleId
        currentEventStart = Date()
    }

    func finalizeCurrentEvent() {
        if let appName = currentAppName,
           let bundleId = currentBundleId,
           let startTime = currentEventStart {
            let duration = Date().timeIntervalSince(startTime)
            let event = FocusEvent(
                appName: appName,
                bundleId: bundleId,
                startTime: startTime,
                duration: duration
            )
            history.insert(event, at: 0)
            currentAppName = nil
            currentBundleId = nil
            currentEventStart = nil
        }
    }

    func save() {
        do {
            try FileManager.default.createDirectory(
                at: storageDirectory,
                withIntermediateDirectories: true
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted

            let data = try encoder.encode(history)
            try data.write(to: todayFilePath)
        } catch {
            print("Failed to save history: \(error)")
        }
    }

    func load() {
        do {
            let data = try Data(contentsOf: todayFilePath)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            history = try decoder.decode([FocusEvent].self, from: data)
        } catch {
            // File doesn't exist or is corrupted - start fresh
            history = []
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run:
```bash
cd FocusStealer && swift test --filter FocusStoreTests
```
Expected: 5 tests pass

**Step 5: Commit**

```bash
git add FocusStealer/Sources/FocusStealer/FocusStore.swift FocusStealer/Tests/FocusStealerTests/FocusStoreTests.swift
git commit -m "feat: add JSON persistence to FocusStore"
```

---

## Task 6: Create FocusWatcher

**Goal:** Create the component that listens for NSWorkspace focus notifications.

**Files:**
- Create: `FocusStealer/Sources/FocusStealer/FocusWatcher.swift`

**Note:** This component interacts with system APIs, so we test it manually rather than with unit tests.

**Step 1: Create the implementation**

Create: `FocusStealer/Sources/FocusStealer/FocusWatcher.swift`

```swift
import AppKit
import Combine

@MainActor
class FocusWatcher: ObservableObject {
    private let store: FocusStore
    private var cancellable: AnyCancellable?

    init(store: FocusStore) {
        self.store = store
    }

    func start() {
        // Get initial focused app
        if let app = NSWorkspace.shared.frontmostApplication {
            store.recordFocusChange(
                appName: app.localizedName ?? "Unknown",
                bundleId: app.bundleIdentifier ?? "unknown"
            )
        }

        // Listen for focus changes
        cancellable = NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleFocusChange(notification)
            }
    }

    func stop() {
        cancellable?.cancel()
        cancellable = nil
        store.finalizeCurrentEvent()
        store.save()
    }

    private func handleFocusChange(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }

        store.recordFocusChange(
            appName: app.localizedName ?? "Unknown",
            bundleId: app.bundleIdentifier ?? "unknown"
        )

        // Auto-save after each change (could debounce for performance)
        store.save()
    }
}
```

**Step 2: Build to verify**

Run:
```bash
cd FocusStealer && swift build
```
Expected: Build succeeds

**Step 3: Commit**

```bash
git add FocusStealer/Sources/FocusStealer/FocusWatcher.swift
git commit -m "feat: add FocusWatcher for NSWorkspace notifications"
```

---

## Task 7: Create MenuBarView UI

**Goal:** Create the dropdown menu UI shown when clicking the menu bar item.

**Files:**
- Create: `FocusStealer/Sources/FocusStealer/MenuBarView.swift`

**Step 1: Create the implementation**

Create: `FocusStealer/Sources/FocusStealer/MenuBarView.swift`

```swift
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var store: FocusStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Currently focused section
            Section {
                if let current = store.currentAppName {
                    HStack {
                        Text(current)
                            .fontWeight(.medium)
                        Spacer()
                        Text("now")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                } else {
                    Text("None")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
            } header: {
                Text("Currently Focused")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }

            Divider()
                .padding(.vertical, 4)

            // Recent history section
            Section {
                if store.history.isEmpty {
                    Text("No history yet")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(store.history.prefix(20)) { event in
                                HStack {
                                    Text(event.appName)
                                    Spacer()
                                    Text("\(formatTimeOfDay(event.startTime)) · \(formatDuration(event.duration))")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
            } header: {
                Text("Recent (today)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
            }

            Divider()
                .padding(.vertical, 4)

            // Quit button
            Button("Quit FocusStealer") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 300)
    }
}
```

**Step 2: Build to verify**

Run:
```bash
cd FocusStealer && swift build
```
Expected: Build succeeds

**Step 3: Commit**

```bash
git add FocusStealer/Sources/FocusStealer/MenuBarView.swift
git commit -m "feat: add MenuBarView dropdown UI"
```

---

## Task 8: Wire Everything Together in App

**Goal:** Update the app entry point to connect all components.

**Files:**
- Modify: `FocusStealer/Sources/FocusStealer/FocusStealerApp.swift`

**Step 1: Update the app entry point**

Update `FocusStealer/Sources/FocusStealer/FocusStealerApp.swift`:

```swift
import SwiftUI

@main
struct FocusStealerApp: App {
    @StateObject private var store = FocusStore()
    @StateObject private var watcher: FocusWatcher

    init() {
        let store = FocusStore()
        _store = StateObject(wrappedValue: store)
        _watcher = StateObject(wrappedValue: FocusWatcher(store: store))
    }

    var body: some Scene {
        MenuBarExtra(store.currentAppName ?? "FocusStealer") {
            MenuBarView(store: store)
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(replacing: .appTermination) {
                Button("Quit FocusStealer") {
                    watcher.stop()
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
    }
}

// App delegate to handle lifecycle
class AppDelegate: NSObject, NSApplicationDelegate {
    var watcher: FocusWatcher?
    var store: FocusStore?

    func applicationDidFinishLaunching(_ notification: Notification) {
        store?.load()
        watcher?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        watcher?.stop()
    }
}
```

**Step 2: Build to verify**

Run:
```bash
cd FocusStealer && swift build
```
Expected: Build succeeds (may have warnings about lifecycle, we'll fix)

**Step 3: Fix app lifecycle with proper initialization**

The StateObject initialization is tricky. Let's simplify:

Update `FocusStealer/Sources/FocusStealer/FocusStealerApp.swift`:

```swift
import SwiftUI

@main
struct FocusStealerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra(appDelegate.store.currentAppName ?? "FocusStealer") {
            MenuBarView(store: appDelegate.store)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let store = FocusStore()
    var watcher: FocusWatcher?

    func applicationDidFinishLaunching(_ notification: Notification) {
        store.load()
        watcher = FocusWatcher(store: store)
        watcher?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        watcher?.stop()
    }
}
```

**Step 4: Build and run to test**

Run:
```bash
cd FocusStealer && swift build && swift run
```
Expected: App appears in menu bar, shows current app name

**Step 5: Manual testing checklist**

- [ ] App appears in menu bar showing current app name
- [ ] Clicking shows dropdown with "Currently Focused" section
- [ ] Switch to another app - menu bar updates
- [ ] Dropdown shows history with timestamps and durations
- [ ] Quit button works
- [ ] Check `~/.focus-stealer/` for JSON file

**Step 6: Commit**

```bash
git add FocusStealer/Sources/FocusStealer/FocusStealerApp.swift
git commit -m "feat: wire up app entry point with all components"
```

---

## Task 9: Run All Tests and Polish

**Goal:** Ensure all tests pass and clean up any issues.

**Step 1: Run full test suite**

Run:
```bash
cd FocusStealer && swift test
```
Expected: All tests pass

**Step 2: Fix any test failures**

If tests fail due to @MainActor issues, update tests to run on main actor:

```swift
@MainActor
final class FocusStoreTests: XCTestCase {
    // ... tests ...
}
```

**Step 3: Build release version**

Run:
```bash
cd FocusStealer && swift build -c release
```
Expected: Release build succeeds

**Step 4: Commit any fixes**

```bash
git add -A
git commit -m "fix: ensure all tests pass with MainActor annotations"
```

---

## Task 10: Update README

**Goal:** Update documentation for the new Swift app.

**Files:**
- Modify: `README.md`

**Step 1: Update README**

Update `README.md` in worktree root:

```markdown
# FocusStealer

A native macOS menu bar app that tracks which applications have focus. Helps identify "focus stealing" apps and understand how you spend time across applications.

## Features

- Shows currently focused app in the menu bar
- Click to see recent focus history with timestamps and durations
- Persists daily history to `~/.focus-stealer/YYYY-MM-DD.json`
- Zero CPU usage while idle (event-driven, no polling)

## Requirements

- macOS 13+ (Ventura)
- Xcode 14+ or Swift 5.9+ (for building)

## Build & Run

```bash
cd FocusStealer
swift build
swift run
```

For a release build:

```bash
swift build -c release
# Binary at .build/release/FocusStealer
```

## Usage

1. Run the app - it appears in your menu bar showing the current app name
2. Click to see your focus history for today
3. Switch between apps - the menu bar updates and history accumulates
4. Quit via the dropdown menu or Cmd+Q

## Data Storage

History is saved to `~/.focus-stealer/` with one JSON file per day:

```
~/.focus-stealer/
├── 2026-02-04.json
├── 2026-02-05.json
└── ...
```

## Legacy Python Version

The original Python CLI tool is still available in the repository root (`focus_stealer.py`). See the original setup instructions if you prefer the CLI version.
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update README for Swift menu bar app"
```

---

## Task 11: Final Integration Test

**Goal:** Complete end-to-end manual test of the app.

**Step 1: Clean build and run**

```bash
cd FocusStealer
swift package clean
swift build -c release
.build/release/FocusStealer
```

**Step 2: Manual testing checklist**

- [ ] App appears in menu bar
- [ ] Shows current app name (not "FocusStealer")
- [ ] Click opens dropdown with proper sections
- [ ] Switch apps multiple times - history accumulates
- [ ] Timestamps show correct times
- [ ] Durations calculate correctly
- [ ] Quit and relaunch - history persists
- [ ] Check JSON file is valid: `cat ~/.focus-stealer/2026-02-04.json | jq .`

**Step 3: Commit any final fixes**

```bash
git add -A
git commit -m "chore: final polish and integration testing"
```

---

## Summary

After completing all tasks, you will have:

1. A Swift Package-based macOS menu bar app
2. FocusEvent data model with Codable support
3. Duration and time formatters with tests
4. FocusStore with in-memory history and JSON persistence
5. FocusWatcher listening to NSWorkspace notifications
6. MenuBarView SwiftUI dropdown UI
7. Updated README documentation

The app will be ready to use. Future enhancements (login item, preferences, past days view) can be added incrementally.

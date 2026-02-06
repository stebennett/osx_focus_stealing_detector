import Foundation
import FocusStealerLib

func runFocusStoreTests() -> (passed: Int, failed: Int) {
    var passed = 0
    var failed = 0

    // Test 1: Initial state
    print("Running testInitialState...")
    let store1 = FocusStore()
    if store1.currentAppName == nil && store1.history.isEmpty {
        print("  PASSED: testInitialState")
        passed += 1
    } else {
        print("  FAILED: testInitialState")
        failed += 1
    }

    // Test 2: Record focus change
    print("Running testRecordFocusChange...")
    let store2 = FocusStore()
    store2.recordFocusChange(appName: "Safari", bundleId: "com.apple.Safari")
    if store2.currentAppName == "Safari" && store2.history.isEmpty {
        print("  PASSED: testRecordFocusChange")
        passed += 1
    } else {
        print("  FAILED: testRecordFocusChange - currentAppName: \(store2.currentAppName ?? "nil"), history count: \(store2.history.count)")
        failed += 1
    }

    // Test 3: Second focus change creates history
    print("Running testRecordSecondFocusChangeCreatesHistory...")
    let store3 = FocusStore()
    store3.recordFocusChange(appName: "Safari", bundleId: "com.apple.Safari")
    Thread.sleep(forTimeInterval: 0.1)
    store3.recordFocusChange(appName: "iTerm2", bundleId: "com.googlecode.iterm2")
    if store3.currentAppName == "iTerm2" &&
       store3.history.count == 1 &&
       store3.history.first?.appName == "Safari" &&
       (store3.history.first?.duration ?? 0) > 0 {
        print("  PASSED: testRecordSecondFocusChangeCreatesHistory")
        passed += 1
    } else {
        print("  FAILED: testRecordSecondFocusChangeCreatesHistory")
        failed += 1
    }

    // Test 4: Ignore same app
    print("Running testIgnoreSameApp...")
    let store4 = FocusStore()
    store4.recordFocusChange(appName: "Safari", bundleId: "com.apple.Safari")
    store4.recordFocusChange(appName: "Safari", bundleId: "com.apple.Safari")
    if store4.currentAppName == "Safari" && store4.history.isEmpty {
        print("  PASSED: testIgnoreSameApp")
        passed += 1
    } else {
        print("  FAILED: testIgnoreSameApp")
        failed += 1
    }

    // Test 5: Save and load history
    print("Running testSaveAndLoadHistory...")
    do {
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

        let store2 = FocusStore(storageDirectory: tempDir)
        store2.load()

        if store2.history.count == 1 && store2.history.first?.appName == "Safari" {
            print("  PASSED: testSaveAndLoadHistory")
            passed += 1
        } else {
            print("  FAILED: testSaveAndLoadHistory - history count: \(store2.history.count)")
            failed += 1
        }
    } catch {
        print("  FAILED: testSaveAndLoadHistory - \(error)")
        failed += 1
    }

    // Test 6: todayTimeByApp returns empty for empty history
    print("Running testTodayTimeByAppEmpty...")
    do {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FocusStealerTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let store = FocusStore(storageDirectory: tempDir)
        let result = store.todayTimeByApp

        if result.isEmpty {
            print("  PASSED: testTodayTimeByAppEmpty")
            passed += 1
        } else {
            print("  FAILED: testTodayTimeByAppEmpty - Expected empty result for empty history")
            failed += 1
        }
    } catch {
        print("  FAILED: testTodayTimeByAppEmpty - \(error)")
        failed += 1
    }

    // Test 7: todayTimeByApp aggregation logic
    print("Running testTodayTimeByAppAggregation...")
    do {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FocusStealerTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let store = FocusStore(storageDirectory: tempDir)

        // Simulate focus changes to build history
        // Using durations > 1 second to pass the filter threshold
        store.recordFocusChange(appName: "Safari", bundleId: "com.apple.Safari")
        Thread.sleep(forTimeInterval: 1.1)
        store.recordFocusChange(appName: "VS Code", bundleId: "com.microsoft.VSCode")
        Thread.sleep(forTimeInterval: 1.2)
        store.recordFocusChange(appName: "Safari", bundleId: "com.apple.Safari")
        Thread.sleep(forTimeInterval: 1.1)
        store.recordFocusChange(appName: "Terminal", bundleId: "com.apple.Terminal")

        let result = store.todayTimeByApp

        // Safari should be first (1.1 + 1.1 = ~2.2s total)
        // VS Code should be second (~1.2s)
        // Terminal is currently active, not in history yet
        var testPassed = true
        var failureReason = ""

        if result.count != 2 {
            testPassed = false
            failureReason = "Expected 2 apps, got \(result.count)"
        } else if result[0].appName != "Safari" {
            testPassed = false
            failureReason = "Expected Safari first, got \(result[0].appName)"
        } else if result[1].appName != "VS Code" {
            testPassed = false
            failureReason = "Expected VS Code second, got \(result[1].appName)"
        } else if result[0].duration <= result[1].duration {
            testPassed = false
            failureReason = "Safari should have more time than VS Code"
        }

        if testPassed {
            print("  PASSED: testTodayTimeByAppAggregation")
            passed += 1
        } else {
            print("  FAILED: testTodayTimeByAppAggregation - \(failureReason)")
            failed += 1
        }
    } catch {
        print("  FAILED: testTodayTimeByAppAggregation - \(error)")
        failed += 1
    }

    // Test 8: todayTimeByApp top 5 + Other bucketing
    print("Running testTodayTimeByAppTop5PlusOther...")
    do {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FocusStealerTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

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

        var testPassed = true
        var failureReason = ""

        // Should have top 5 + Other = 6 entries
        if result.count != 6 {
            testPassed = false
            failureReason = "Expected 6 entries (top 5 + Other), got \(result.count)"
        } else if result[0].appName != "App1" {
            testPassed = false
            failureReason = "Expected App1 first, got \(result[0].appName)"
        } else if result[1].appName != "App2" {
            testPassed = false
            failureReason = "Expected App2 second, got \(result[1].appName)"
        } else if result[2].appName != "App3" {
            testPassed = false
            failureReason = "Expected App3 third, got \(result[2].appName)"
        } else if result[3].appName != "App4" {
            testPassed = false
            failureReason = "Expected App4 fourth, got \(result[3].appName)"
        } else if result[4].appName != "App5" {
            testPassed = false
            failureReason = "Expected App5 fifth, got \(result[4].appName)"
        } else if result[5].appName != "Other" {
            testPassed = false
            failureReason = "Expected Other last, got \(result[5].appName)"
        } else if !(result[5].duration >= 2.5 && result[5].duration <= 3.5) {
            testPassed = false
            failureReason = "Other duration should be ~3s, got \(result[5].duration)"
        }

        if testPassed {
            print("  PASSED: testTodayTimeByAppTop5PlusOther")
            passed += 1
        } else {
            print("  FAILED: testTodayTimeByAppTop5PlusOther - \(failureReason)")
            failed += 1
        }
    } catch {
        print("  FAILED: testTodayTimeByAppTop5PlusOther - \(error)")
        failed += 1
    }

    return (passed, failed)
}

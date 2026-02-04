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

    return (passed, failed)
}

import Foundation
import FocusStealerLib

// Test runner for FocusEvent
func runFocusEventTests() -> (passed: Int, failed: Int) {
    var passed = 0
    var failed = 0

    // Test 1: FocusEvent creation
    print("Running testFocusEventCreation...")
    do {
        let now = Date()
        let event = FocusEvent(
            appName: "Safari",
            bundleId: "com.apple.Safari",
            startTime: now,
            duration: 0
        )

        if event.appName == "Safari" &&
           event.bundleId == "com.apple.Safari" &&
           event.startTime == now &&
           event.duration == 0 {
            print("  PASSED: testFocusEventCreation")
            passed += 1
        } else {
            print("  FAILED: testFocusEventCreation - property mismatch")
            failed += 1
        }
    }

    // Test 2: FocusEvent encode/decode
    print("Running testFocusEventEncodeDecode...")
    do {
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

        if decoded.appName == event.appName &&
           decoded.bundleId == event.bundleId &&
           decoded.duration == event.duration {
            print("  PASSED: testFocusEventEncodeDecode")
            passed += 1
        } else {
            print("  FAILED: testFocusEventEncodeDecode - decoded values don't match")
            failed += 1
        }
    } catch {
        print("  FAILED: testFocusEventEncodeDecode - \(error)")
        failed += 1
    }

    return (passed, failed)
}

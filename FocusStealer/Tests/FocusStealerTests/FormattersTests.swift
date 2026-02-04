import Foundation
import FocusStealerLib

func runFormattersTests() -> (passed: Int, failed: Int) {
    var passed = 0
    var failed = 0

    // Test 1: formatDuration - seconds only
    print("Running testFormatDurationSeconds...")
    if formatDuration(45) == "45s" {
        print("  PASSED: testFormatDurationSeconds")
        passed += 1
    } else {
        print("  FAILED: testFormatDurationSeconds - got \(formatDuration(45))")
        failed += 1
    }

    // Test 2: formatDuration - minutes and seconds
    print("Running testFormatDurationMinutesAndSeconds...")
    if formatDuration(200) == "3m 20s" {
        print("  PASSED: testFormatDurationMinutesAndSeconds")
        passed += 1
    } else {
        print("  FAILED: testFormatDurationMinutesAndSeconds - got \(formatDuration(200))")
        failed += 1
    }

    // Test 3: formatDuration - hours and minutes
    print("Running testFormatDurationHoursAndMinutes...")
    if formatDuration(3900) == "1h 5m" {
        print("  PASSED: testFormatDurationHoursAndMinutes")
        passed += 1
    } else {
        print("  FAILED: testFormatDurationHoursAndMinutes - got \(formatDuration(3900))")
        failed += 1
    }

    // Test 4: formatDuration - zero
    print("Running testFormatDurationZero...")
    if formatDuration(0) == "0s" {
        print("  PASSED: testFormatDurationZero")
        passed += 1
    } else {
        print("  FAILED: testFormatDurationZero - got \(formatDuration(0))")
        failed += 1
    }

    // Test 5: formatTimeOfDay - contains minutes
    print("Running testFormatTimeOfDay...")
    var components = DateComponents()
    components.year = 2026
    components.month = 2
    components.day = 4
    components.hour = 14
    components.minute = 31
    let calendar = Calendar.current
    if let date = calendar.date(from: components) {
        let result = formatTimeOfDay(date)
        if result.contains("31") {
            print("  PASSED: testFormatTimeOfDay")
            passed += 1
        } else {
            print("  FAILED: testFormatTimeOfDay - expected time containing '31', got \(result)")
            failed += 1
        }
    } else {
        print("  FAILED: testFormatTimeOfDay - could not create date")
        failed += 1
    }

    return (passed, failed)
}

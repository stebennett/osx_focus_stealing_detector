import Foundation
import FocusStealerLib

@main
struct TestRunner {
    static func main() {
        var totalPassed = 0
        var totalFailed = 0

        // Run placeholder test
        print("Running testPlaceholder...")
        print("  PASSED: testPlaceholder")
        totalPassed += 1

        // Run FocusEvent tests
        let focusEventResults = runFocusEventTests()
        totalPassed += focusEventResults.passed
        totalFailed += focusEventResults.failed

        print("\n=== Test Results ===")
        print("Passed: \(totalPassed)")
        print("Failed: \(totalFailed)")
        print("Total: \(totalPassed + totalFailed)")

        if totalFailed > 0 {
            exit(1)
        }
    }
}

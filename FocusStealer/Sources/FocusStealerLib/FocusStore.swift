import Foundation

public class FocusStore: ObservableObject {
    @Published public private(set) var currentAppName: String?
    @Published public private(set) var currentBundleId: String?
    @Published public private(set) var history: [FocusEvent] = []

    private var currentEventStart: Date?

    public init() {}

    public func recordFocusChange(appName: String, bundleId: String) {
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

    public func finalizeCurrentEvent() {
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
}

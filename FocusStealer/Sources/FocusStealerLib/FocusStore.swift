import Foundation

public class FocusStore: ObservableObject {
    @Published public private(set) var currentAppName: String?
    @Published public private(set) var currentBundleId: String?
    @Published public private(set) var history: [FocusEvent] = []

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

    private var currentEventStart: Date?
    private let storageDirectory: URL

    public init(storageDirectory: URL? = nil) {
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

    public func save() {
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

    public func load() {
        do {
            let data = try Data(contentsOf: todayFilePath)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            history = try decoder.decode([FocusEvent].self, from: data)
        } catch {
            history = []
        }
    }
}

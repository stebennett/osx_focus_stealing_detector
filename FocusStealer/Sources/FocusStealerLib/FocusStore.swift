import Foundation

public class FocusStore: ObservableObject {
    @Published public private(set) var currentAppName: String?
    @Published public private(set) var currentBundleId: String?
    @Published public private(set) var history: [FocusEvent] = []

    public var todayTimeByApp: [(appName: String, duration: TimeInterval)] {
        return []
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

import Foundation

public struct FocusEvent: Codable, Identifiable, Sendable {
    public let id: UUID
    public let appName: String
    public let bundleId: String
    public let startTime: Date
    public var duration: TimeInterval

    public init(
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

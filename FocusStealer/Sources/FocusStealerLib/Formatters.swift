import Foundation

public func formatDuration(_ seconds: TimeInterval) -> String {
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

public func formatTimeOfDay(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mma"
    return formatter.string(from: date).lowercased()
}

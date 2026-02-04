import AppKit
import Combine
import FocusStealerLib

public class FocusWatcher: ObservableObject {
    private let store: FocusStore
    private var cancellable: AnyCancellable?

    public init(store: FocusStore) {
        self.store = store
    }

    public func start() {
        // Get initial focused app
        if let app = NSWorkspace.shared.frontmostApplication {
            store.recordFocusChange(
                appName: app.localizedName ?? "Unknown",
                bundleId: app.bundleIdentifier ?? "unknown"
            )
        }

        // Listen for focus changes
        cancellable = NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleFocusChange(notification)
            }
    }

    public func stop() {
        cancellable?.cancel()
        cancellable = nil
        store.finalizeCurrentEvent()
        store.save()
    }

    private func handleFocusChange(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }

        store.recordFocusChange(
            appName: app.localizedName ?? "Unknown",
            bundleId: app.bundleIdentifier ?? "unknown"
        )

        // Auto-save after each change
        store.save()
    }
}

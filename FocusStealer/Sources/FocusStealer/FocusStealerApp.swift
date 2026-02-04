import SwiftUI
import FocusStealerLib

@main
struct FocusStealerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var store: FocusStore

    init() {
        let delegate = AppDelegate.shared
        self.store = delegate.store
    }

    var body: some Scene {
        MenuBarExtra(store.currentAppName ?? "FocusStealer") {
            MenuBarView(store: store)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    static let shared = AppDelegate()
    let store = FocusStore()
    var watcher: FocusWatcher?

    override init() {
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        store.load()
        watcher = FocusWatcher(store: store)
        watcher?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        watcher?.stop()
    }
}

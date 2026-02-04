import SwiftUI
import FocusStealerLib

@main
struct FocusStealerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var store: FocusStore

    init() {
        self.store = AppDelegate.shared.store
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(store: store)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "eye")
                Text(store.currentAppName ?? "")
            }
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    static var shared: AppDelegate!
    let store = FocusStore()
    var watcher: FocusWatcher?

    override init() {
        super.init()
        AppDelegate.shared = self
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

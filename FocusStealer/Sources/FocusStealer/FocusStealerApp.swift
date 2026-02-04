import SwiftUI
import FocusStealerLib

@main
struct FocusStealerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra(appDelegate.store.currentAppName ?? "FocusStealer") {
            MenuBarView(store: appDelegate.store)
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let store = FocusStore()
    var watcher: FocusWatcher?

    func applicationDidFinishLaunching(_ notification: Notification) {
        store.load()
        watcher = FocusWatcher(store: store)
        watcher?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        watcher?.stop()
    }
}

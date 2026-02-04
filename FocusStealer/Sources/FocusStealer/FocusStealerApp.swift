import SwiftUI
import FocusStealerLib

@main
struct FocusStealerApp: App {
    var body: some Scene {
        MenuBarExtra("FocusStealer", systemImage: "eye") {
            Text("Hello, FocusStealer!")
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

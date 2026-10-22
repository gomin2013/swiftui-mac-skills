import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        // Regular Dock / Launchpad app: ⌘Q / ⌘W come from the standard app menu.
        WindowGroup("My App") {
            ContentView()
                .frame(minWidth: 760, minHeight: 540)
        }
        .windowResizability(.contentMinSize)
        .commands {
            // One main window: drop File › New Window so ⌘N is free for the app's own "Add" action.
            CommandGroup(replacing: .newItem) {}
        }
    }
}

struct ContentView: View {
    var body: some View {
        Text("Hello, My App")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

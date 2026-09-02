import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Today", systemImage: "sparkles")
                }

            LibraryView()
                .tabItem {
                    Label("Ideas", systemImage: "tray.full")
                }

            ComposerView()
                .tabItem {
                    Label("Compose", systemImage: "square.stack.3d.up")
                }

            SettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
    }
}

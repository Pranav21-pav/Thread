import SwiftUI
import SwiftData

@main
struct ThreadApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [MusicIdea.self, SongDraft.self, SongSection.self, SongClip.self])
    }
}

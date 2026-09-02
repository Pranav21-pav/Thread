import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Thread") {
                    LabeledContent("Purpose", value: "Capture and compose")
                    LabeledContent("Storage", value: "On-device")
                    LabeledContent("Minimum iOS", value: "17.0")
                }

                Section("How to use it") {
                    Label("Save a recording, lyric, riff, or chord loop from Today or Ideas.", systemImage: "1.circle")
                    Label("Create a song draft in Compose and add sections while the structure is still loose.", systemImage: "2.circle")
                    Label("Attach older ideas to sections and use the chord strip to test movement quickly.", systemImage: "3.circle")
                    Label("Export the draft as text when you move into Ableton or a longer writing session.", systemImage: "4.circle")
                }

                Section("Privacy") {
                    Text("This version has no account, analytics SDK, cloud sync, or external AI service. Notes and audio recordings stay in the app’s local storage unless you export a draft.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("About")
        }
    }
}

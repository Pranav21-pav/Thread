import SwiftUI
import SwiftData

struct IdeaDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var idea: MusicIdea

    @StateObject private var player = AudioPlayerService()
    @State private var showingDeleteConfirmation = false

    var body: some View {
        Form {
            Section("Idea") {
                TextField("Title", text: $idea.title)
                Picker("Type", selection: Binding(
                    get: { idea.category },
                    set: { idea.category = $0; idea.touch() }
                )) {
                    ForEach(IdeaCategory.allCases) { category in
                        Label(category.label, systemImage: category.systemImage)
                            .tag(category)
                    }
                }
                Toggle("Favorite", isOn: $idea.isFavorite)
            }

            if let audioFileName = idea.audioFileName {
                Section("Recording") {
                    Button {
                        player.toggle(fileName: audioFileName)
                    } label: {
                        Label(
                            player.isPlaying && player.playingFileName == audioFileName ? "Stop Playback" : "Play Recording",
                            systemImage: player.isPlaying && player.playingFileName == audioFileName ? "stop.circle.fill" : "play.circle.fill"
                        )
                    }
                    if let errorMessage = player.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            Section("Notes") {
                TextField("Lyrics, chords, fingering, or next steps", text: $idea.note, axis: .vertical)
                    .lineLimit(5...14)
            }

            Section("Musical context") {
                TextField("Instrument", text: $idea.instrument)
                TextField("Key or tonal center", text: $idea.keyCenter)
                Stepper("Tempo: \(idea.bpm > 0 ? "\(idea.bpm) BPM" : "Not set")", value: $idea.bpm, in: 0...300)
                TextField("Tags separated by commas", text: $idea.tagsCSV)
            }

            Section("Saved") {
                LabeledContent("Created", value: idea.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Last edited", value: idea.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }

            Section {
                Button("Delete Idea", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            }
        }
        .navigationTitle(idea.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            idea.touch()
            try? modelContext.save()
            player.stop()
        }
        .confirmationDialog("Delete this idea?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Idea", role: .destructive) {
                AudioFileStore.delete(fileName: idea.audioFileName)
                modelContext.delete(idea)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("The saved note and its local recording will be removed.")
        }
    }
}

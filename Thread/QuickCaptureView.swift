import SwiftUI
import SwiftData

struct QuickCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @StateObject private var recorder = AudioRecorderService()

    @State private var title = ""
    @State private var note = ""
    @State private var category: IdeaCategory = .riff
    @State private var instrument = ""
    @State private var keyCenter = ""
    @State private var bpmText = ""
    @State private var tagsCSV = ""
    @State private var recordedFileName: String?

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        recordedFileName != nil ||
        recorder.isRecording
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Quick capture") {
                    TextField("Title, such as chorus melody", text: $title)
                    Picker("Type", selection: $category) {
                        ForEach(IdeaCategory.allCases) { category in
                            Label(category.label, systemImage: category.systemImage)
                                .tag(category)
                        }
                    }
                }

                Section("Recording") {
                    RecordingButton(isRecording: recorder.isRecording, elapsedTime: recorder.elapsedTime) {
                        Task {
                            if recorder.isRecording {
                                recordedFileName = recorder.stopRecording()
                            } else {
                                await recorder.startRecording()
                            }
                        }
                    }

                    if let recordedFileName {
                        Label("Recording saved for this idea", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                        Button("Discard Recording", role: .destructive) {
                            AudioFileStore.delete(fileName: recordedFileName)
                            self.recordedFileName = nil
                        }
                    }

                    if let errorMessage = recorder.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Write while the idea is fresh") {
                    TextField("Lyrics, chord loop, fingering, or what to try next", text: $note, axis: .vertical)
                        .lineLimit(4...10)
                }

                Section("Optional musical context") {
                    TextField("Instrument, such as guitar or saxophone", text: $instrument)
                    TextField("Key or tonal center, such as F", text: $keyCenter)
                    TextField("Tempo in BPM", text: $bpmText)
                        .keyboardType(.numberPad)
                    TextField("Tags separated by commas", text: $tagsCSV)
                }
            }
            .navigationTitle("New Idea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        recorder.cancelRecording()
                        AudioFileStore.delete(fileName: recordedFileName)
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        if recorder.isRecording {
            recordedFileName = recorder.stopRecording()
        }

        let idea = MusicIdea(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            instrument: instrument.trimmingCharacters(in: .whitespacesAndNewlines),
            keyCenter: keyCenter.trimmingCharacters(in: .whitespacesAndNewlines),
            bpm: Int(bpmText) ?? 0,
            tagsCSV: tagsCSV,
            audioFileName: recordedFileName
        )

        modelContext.insert(idea)
        try? modelContext.save()
        dismiss()
    }
}

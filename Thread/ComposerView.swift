import SwiftUI
import SwiftData

struct ComposerView: View {
    @Query(sort: \SongDraft.updatedAt, order: .reverse) private var drafts: [SongDraft]
    @State private var showingNewDraft = false

    var body: some View {
        NavigationStack {
            Group {
                if drafts.isEmpty {
                    EmptyStateView(
                        title: "No song drafts yet",
                        message: "Build a song section by section while you are away from your instrument or DAW.",
                        systemImage: "square.stack.3d.up"
                    )
                } else {
                    List {
                        ForEach(drafts, id: \.id) { draft in
                            NavigationLink {
                                DraftEditorView(draft: draft)
                            } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(draft.displayTitle)
                                        .font(.headline)
                                    Text("\(draft.sortedSections.count) sections · \(draft.keyCenter.isEmpty ? "key not set" : "key of \(draft.keyCenter)")")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text("Updated \(draft.updatedAt.compactRelativeDescription)")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Compose")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewDraft = true
                    } label: {
                        Label("New song", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewDraft) {
                NewDraftView()
            }
        }
    }
}

struct NewDraftView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var keyCenter = "C"
    @State private var bpmText = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Song") {
                    TextField("Working title", text: $title)
                    Picker("Key", selection: $keyCenter) {
                        ForEach(HarmonyHelper.supportedKeys, id: \.self) { key in
                            Text(key).tag(key)
                        }
                    }
                    TextField("Tempo in BPM", text: $bpmText)
                        .keyboardType(.numberPad)
                }

                Section("Starting note") {
                    TextField("Theme, lyric image, reference, or next step", text: $note, axis: .vertical)
                        .lineLimit(4...8)
                }
            }
            .navigationTitle("New Song Draft")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let draft = SongDraft(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            keyCenter: keyCenter,
                            bpm: Int(bpmText) ?? 0,
                            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        modelContext.insert(draft)
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

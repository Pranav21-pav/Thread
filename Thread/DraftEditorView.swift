import SwiftUI
import SwiftData

struct DraftEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var draft: SongDraft

    @Query(sort: \MusicIdea.updatedAt, order: .reverse) private var ideas: [MusicIdea]

    @State private var showingAddSection = false
    @State private var sectionForIdeaPicker: SongSection?
    @State private var showingDeleteConfirmation = false
    @State private var promptOffset = 0

    private var currentPrompt: String {
        let prompts = CompositionCoach.prompts
        let base = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 1
        return prompts[(base + promptOffset - 1) % prompts.count]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                songHeader
                coachCard

                if draft.sortedSections.isEmpty {
                    EmptyStateView(
                        title: "Add your first section",
                        message: "Start with a verse, chorus, interlude, or any loose musical block. Each section has a chord scratchpad and lyric notebook.",
                        systemImage: "rectangle.stack.badge.plus"
                    )
                    .frame(minHeight: 260)
                } else {
                    ForEach(draft.sortedSections, id: \.id) { section in
                        SectionEditorCard(
                            draftKey: draft.keyCenter,
                            section: section,
                            ideas: ideas,
                            onAddIdea: { sectionForIdeaPicker = section },
                            onMoveUp: { move(section: section, delta: -1) },
                            onMoveDown: { move(section: section, delta: 1) },
                            onDelete: { delete(section: section) },
                            onEdited: { touchDraft() }
                        )
                    }
                }

                Button {
                    showingAddSection = true
                } label: {
                    Label("Add Section", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle(draft.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(item: DraftExport.text(for: draft)) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                Button {
                    showingAddSection = true
                } label: {
                    Label("Add section", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSection) {
            AddSectionView(draft: draft)
        }
        .sheet(item: $sectionForIdeaPicker) { section in
            IdeaPickerView(section: section, draft: draft)
        }
        .onDisappear {
            touchDraft()
            try? modelContext.save()
        }
        .confirmationDialog("Delete this song draft?", isPresented: $showingDeleteConfirmation) {
            Button("Delete Draft", role: .destructive) {
                modelContext.delete(draft)
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    private var songHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Song title", text: $draft.title)
                .font(.title2.weight(.semibold))

            HStack {
                Picker("Key", selection: $draft.keyCenter) {
                    ForEach(HarmonyHelper.supportedKeys, id: \.self) { key in
                        Text(key).tag(key)
                    }
                }
                .pickerStyle(.menu)

                Spacer()

                Stepper("\(draft.bpm > 0 ? "\(draft.bpm) BPM" : "Tempo")", value: $draft.bpm, in: 0...300)
                    .fixedSize()
            }

            TextField("Overall notes, theme, or production direction", text: $draft.note, axis: .vertical)
                .lineLimit(2...6)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onChange(of: draft.title) { _, _ in touchDraft() }
        .onChange(of: draft.keyCenter) { _, _ in touchDraft() }
        .onChange(of: draft.bpm) { _, _ in touchDraft() }
        .onChange(of: draft.note) { _, _ in touchDraft() }
    }

    private var coachCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Label("Try this while composing", systemImage: "wand.and.stars")
                    .font(.headline)
                Spacer()
                Button {
                    promptOffset += 1
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Show another prompt")
            }
            Text(currentPrompt)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func move(section: SongSection, delta: Int) {
        var sorted = draft.sortedSections
        guard let currentIndex = sorted.firstIndex(where: { $0.id == section.id }) else { return }
        let newIndex = currentIndex + delta
        guard sorted.indices.contains(newIndex) else { return }

        sorted.swapAt(currentIndex, newIndex)
        for (index, section) in sorted.enumerated() {
            section.order = index
            section.touch()
        }
        touchDraft()
    }

    private func delete(section: SongSection) {
        draft.sections.removeAll { $0.id == section.id }
        modelContext.delete(section)
        for (index, section) in draft.sortedSections.enumerated() {
            section.order = index
        }
        touchDraft()
    }

    private func touchDraft() {
        draft.touch()
        try? modelContext.save()
    }
}

struct SectionEditorCard: View {
    @Environment(\.modelContext) private var modelContext

    let draftKey: String
    @Bindable var section: SongSection
    let ideas: [MusicIdea]
    let onAddIdea: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void
    let onEdited: () -> Void

    private var linkedIdeas: [UUID: MusicIdea] {
        Dictionary(uniqueKeysWithValues: ideas.map { ($0.id, $0) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    TextField("Section title", text: $section.title)
                        .font(.headline)
                    Picker("Section type", selection: Binding(
                        get: { section.kind },
                        set: { section.kind = $0; edited() }
                    )) {
                        ForEach(SectionKind.allCases) { kind in
                            Text(kind.label).tag(kind)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Spacer()

                Menu {
                    Button("Move Up", systemImage: "arrow.up", action: onMoveUp)
                    Button("Move Down", systemImage: "arrow.down", action: onMoveDown)
                    Divider()
                    Button("Delete Section", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Chord scratchpad")
                    .font(.subheadline.weight(.semibold))
                TextField("Example: F  G  Em  Am", text: $section.chords, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("Tap to append a chord in \(draftKey) major")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(Array(HarmonyHelper.diatonicChords(for: draftKey).enumerated()), id: \.offset) { index, chord in
                            ChordChip(chord: chord, role: HarmonyHelper.label(forDiatonicIndex: index)) {
                                append(chord)
                            }
                        }
                    }
                }

                Text("Color chords")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(Array(HarmonyHelper.colorChords(for: draftKey).enumerated()), id: \.offset) { index, chord in
                            ChordChip(chord: chord, role: HarmonyHelper.label(forColorIndex: index)) {
                                append(chord)
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Lyrics and arrangement notes")
                    .font(.subheadline.weight(.semibold))
                TextEditor(text: $section.lyricNotes)
                    .frame(minHeight: 100)
                    .padding(6)
                    .background(.background, in: RoundedRectangle(cornerRadius: 9))
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Attached ideas")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Button(action: onAddIdea) {
                        Label("Attach", systemImage: "paperclip")
                    }
                    .font(.caption)
                }

                if section.sortedClips.isEmpty {
                    Text("Attach a recording, lyric fragment, or riff from your library.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(section.sortedClips, id: \.id) { clip in
                        HStack {
                            Image(systemName: clip.category.systemImage)
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(linkedIdeas[clip.fragmentID]?.displayTitle ?? clip.titleSnapshot)
                                    .font(.subheadline.weight(.medium))
                                Text(clip.category.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                section.clips.removeAll { $0.id == clip.id }
                                modelContext.delete(clip)
                                edited()
                            } label: {
                                Image(systemName: "xmark.circle")
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onChange(of: section.title) { _, _ in edited() }
        .onChange(of: section.chords) { _, _ in edited() }
        .onChange(of: section.lyricNotes) { _, _ in edited() }
    }

    private func append(_ chord: String) {
        let trimmed = section.chords.trimmingCharacters(in: .whitespacesAndNewlines)
        section.chords = trimmed.isEmpty ? chord : "\(trimmed)  \(chord)"
        edited()
    }

    private func edited() {
        section.touch()
        onEdited()
    }
}

struct AddSectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var draft: SongDraft
    @State private var kind: SectionKind = .verse
    @State private var title = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Section type", selection: $kind) {
                    ForEach(SectionKind.allCases) { kind in
                        Text(kind.label).tag(kind)
                    }
                }
                TextField("Optional custom title", text: $title)
            }
            .navigationTitle("Add Section")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let section = SongSection(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            kind: kind,
                            order: draft.sections.count
                        )
                        modelContext.insert(section)
                        draft.sections.append(section)
                        draft.touch()
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct IdeaPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var section: SongSection
    @Bindable var draft: SongDraft
    @Query(sort: \MusicIdea.updatedAt, order: .reverse) private var ideas: [MusicIdea]
    @State private var searchText = ""

    private var filteredIdeas: [MusicIdea] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ideas }
        return ideas.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed) ||
            $0.note.localizedCaseInsensitiveContains(trimmed) ||
            $0.tagsCSV.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if ideas.isEmpty {
                    EmptyStateView(
                        title: "No saved ideas",
                        message: "Capture a riff, lyric, or recording first, then attach it to this section.",
                        systemImage: "paperclip"
                    )
                } else {
                    List(filteredIdeas, id: \.id) { idea in
                        Button {
                            attach(idea)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(idea.displayTitle)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                HStack {
                                    CategoryBadge(category: idea.category)
                                    MetadataLine(idea: idea)
                                }
                                if !idea.note.isEmpty {
                                    Text(idea.note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Attach an Idea")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func attach(_ idea: MusicIdea) {
        let clip = SongClip(
            fragmentID: idea.id,
            titleSnapshot: idea.displayTitle,
            category: idea.category,
            noteSnapshot: idea.note,
            order: section.clips.count
        )
        modelContext.insert(clip)
        section.clips.append(clip)
        section.touch()
        draft.touch()
        try? modelContext.save()
        dismiss()
    }
}

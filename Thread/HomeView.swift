import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \MusicIdea.updatedAt, order: .reverse) private var ideas: [MusicIdea]
    @Query(sort: \SongDraft.updatedAt, order: .reverse) private var drafts: [SongDraft]
    @State private var showingCapture = false

    private var surfacedIdeas: [MusicIdea] {
        Array(ideas.sorted { $0.updatedAt < $1.updatedAt }.prefix(3))
    }

    private var compatiblePair: (MusicIdea, MusicIdea)? {
        for first in ideas {
            for second in ideas where first.id != second.id {
                let sameKey = !first.keyCenter.isEmpty && first.keyCenter == second.keyCenter
                let closeTempo = first.bpm > 0 && second.bpm > 0 && abs(first.bpm - second.bpm) <= 12
                if sameKey || closeTempo {
                    return (first, second)
                }
            }
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    stats
                    captureCard
                    composePrompt
                    dailyThreads
                    recentDrafts
                }
                .padding()
            }
            .navigationTitle("Thread")
            .sheet(isPresented: $showingCapture) {
                QuickCaptureView()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Your musical notebook")
                .font(.title2.weight(.semibold))
            Text("Capture something small, then connect it to a song later.")
                .foregroundStyle(.secondary)
        }
    }

    private var stats: some View {
        HStack(spacing: 12) {
            statCard(value: "\(ideas.count)", label: "Ideas", icon: "lightbulb")
            statCard(value: "\(drafts.count)", label: "Drafts", icon: "music.note.list")
            statCard(value: "\(ideas.filter(\.hasAudio).count)", label: "Recordings", icon: "waveform")
        }
    }

    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.bold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var captureCard: some View {
        Button {
            showingCapture = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 38))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Capture an idea")
                        .font(.headline)
                    Text("Record audio, save lyrics, or jot down chords.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var composePrompt: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Composition prompt", systemImage: "wand.and.stars")
                .font(.headline)
            Text(CompositionCoach.prompt())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var dailyThreads: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today’s threads")
                .font(.title3.weight(.semibold))

            if ideas.isEmpty {
                Text("Your older ideas and compatible fragments will appear here after you save a few notes or recordings.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(surfacedIdeas, id: \.id) { idea in
                    NavigationLink {
                        IdeaDetailView(idea: idea)
                    } label: {
                        surfacedIdeaCard(idea)
                    }
                    .buttonStyle(.plain)
                }

                if let pair = compatiblePair {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Try a connection", systemImage: "link")
                            .font(.headline)
                        Text("Combine “\(pair.0.displayTitle)” with “\(pair.1.displayTitle)”. They share a key or a nearby tempo.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private func surfacedIdeaCard(_ idea: MusicIdea) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                CategoryBadge(category: idea.category)
                Spacer()
                Text("Updated \(idea.updatedAt.compactRelativeDescription)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(idea.displayTitle)
                .font(.headline)
            if !idea.note.isEmpty {
                Text(idea.note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            MetadataLine(idea: idea)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var recentDrafts: some View {
        if !drafts.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Continue composing")
                    .font(.title3.weight(.semibold))

                ForEach(drafts.prefix(3), id: \.id) { draft in
                    NavigationLink {
                        DraftEditorView(draft: draft)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(draft.displayTitle)
                                    .font(.headline)
                                Text("\(draft.sections.count) sections · updated \(draft.updatedAt.compactRelativeDescription)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

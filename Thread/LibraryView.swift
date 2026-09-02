import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(sort: \MusicIdea.updatedAt, order: .reverse) private var ideas: [MusicIdea]
    @State private var searchText = ""
    @State private var selectedCategory: IdeaCategory?
    @State private var showingCapture = false

    private var filteredIdeas: [MusicIdea] {
        ideas.filter { idea in
            let matchesCategory = selectedCategory == nil || idea.category == selectedCategory
            let search = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = search.isEmpty ||
                idea.title.localizedCaseInsensitiveContains(search) ||
                idea.note.localizedCaseInsensitiveContains(search) ||
                idea.instrument.localizedCaseInsensitiveContains(search) ||
                idea.keyCenter.localizedCaseInsensitiveContains(search) ||
                idea.tagsCSV.localizedCaseInsensitiveContains(search)
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if ideas.isEmpty {
                    EmptyStateView(
                        title: "No ideas yet",
                        message: "Save a riff, lyric line, chord loop, or quick recording when inspiration appears.",
                        systemImage: "music.note.list"
                    )
                } else {
                    List {
                        ForEach(filteredIdeas, id: \.id) { idea in
                            NavigationLink {
                                IdeaDetailView(idea: idea)
                            } label: {
                                ideaRow(idea)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Idea Library")
            .searchable(text: $searchText, prompt: "Search lyrics, tags, key, or instrument")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("All ideas") {
                            selectedCategory = nil
                        }
                        Divider()
                        ForEach(IdeaCategory.allCases) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                Label(category.label, systemImage: category.systemImage)
                            }
                        }
                    } label: {
                        Label(selectedCategory?.label ?? "Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCapture = true
                    } label: {
                        Label("New idea", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCapture) {
                QuickCaptureView()
            }
        }
    }

    private func ideaRow(_ idea: MusicIdea) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(idea.displayTitle)
                    .font(.headline)
                if idea.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                }
                Spacer()
            }
            HStack {
                CategoryBadge(category: idea.category)
                MetadataLine(idea: idea)
            }
            if !idea.note.isEmpty {
                Text(idea.note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

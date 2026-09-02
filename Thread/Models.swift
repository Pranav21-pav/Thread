import Foundation
import SwiftData

// MARK: - Idea Types

enum IdeaCategory: String, CaseIterable, Codable, Identifiable {
    case riff
    case melody
    case chords
    case lyrics
    case rhythm
    case practiceTake
    case songSection

    var id: String { rawValue }

    var label: String {
        switch self {
        case .riff: return "Riff"
        case .melody: return "Melody"
        case .chords: return "Chords"
        case .lyrics: return "Lyrics"
        case .rhythm: return "Rhythm"
        case .practiceTake: return "Practice Take"
        case .songSection: return "Song Section"
        }
    }

    var systemImage: String {
        switch self {
        case .riff: return "guitars"
        case .melody: return "music.note"
        case .chords: return "music.note.list"
        case .lyrics: return "text.quote"
        case .rhythm: return "metronome"
        case .practiceTake: return "waveform"
        case .songSection: return "square.stack.3d.up"
        }
    }
}

enum SectionKind: String, CaseIterable, Codable, Identifiable {
    case intro
    case verse
    case preChorus
    case chorus
    case bridge
    case interlude
    case solo
    case outro
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .intro: return "Intro"
        case .verse: return "Verse"
        case .preChorus: return "Pre-Chorus"
        case .chorus: return "Chorus"
        case .bridge: return "Bridge"
        case .interlude: return "Interlude"
        case .solo: return "Solo"
        case .outro: return "Outro"
        case .other: return "Other"
        }
    }
}

// MARK: - SwiftData Models

@Model
final class MusicIdea {
    @Attribute(.unique) var id: UUID
    var title: String
    var note: String
    var categoryRaw: String
    var instrument: String
    var keyCenter: String
    var bpm: Int
    var tagsCSV: String
    var createdAt: Date
    var updatedAt: Date
    var audioFileName: String?
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        title: String,
        note: String = "",
        category: IdeaCategory = .riff,
        instrument: String = "",
        keyCenter: String = "",
        bpm: Int = 0,
        tagsCSV: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        audioFileName: String? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.categoryRaw = category.rawValue
        self.instrument = instrument
        self.keyCenter = keyCenter
        self.bpm = bpm
        self.tagsCSV = tagsCSV
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.audioFileName = audioFileName
        self.isFavorite = isFavorite
    }

    var category: IdeaCategory {
        get { IdeaCategory(rawValue: categoryRaw) ?? .riff }
        set { categoryRaw = newValue.rawValue }
    }

    var tags: [String] {
        tagsCSV
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var hasAudio: Bool {
        audioFileName?.isEmpty == false
    }

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled Idea" : trimmed
    }

    func touch() {
        updatedAt = .now
    }
}

@Model
final class SongDraft {
    @Attribute(.unique) var id: UUID
    var title: String
    var keyCenter: String
    var bpm: Int
    var note: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var sections: [SongSection]

    init(
        id: UUID = UUID(),
        title: String,
        keyCenter: String = "C",
        bpm: Int = 0,
        note: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        sections: [SongSection] = []
    ) {
        self.id = id
        self.title = title
        self.keyCenter = keyCenter
        self.bpm = bpm
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sections = sections
    }

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled Song" : trimmed
    }

    var sortedSections: [SongSection] {
        sections.sorted { $0.order < $1.order }
    }

    func touch() {
        updatedAt = .now
    }
}

@Model
final class SongSection {
    @Attribute(.unique) var id: UUID
    var title: String
    var kindRaw: String
    var order: Int
    var chords: String
    var lyricNotes: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var clips: [SongClip]

    init(
        id: UUID = UUID(),
        title: String,
        kind: SectionKind = .verse,
        order: Int = 0,
        chords: String = "",
        lyricNotes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        clips: [SongClip] = []
    ) {
        self.id = id
        self.title = title
        self.kindRaw = kind.rawValue
        self.order = order
        self.chords = chords
        self.lyricNotes = lyricNotes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.clips = clips
    }

    var kind: SectionKind {
        get { SectionKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? kind.label : trimmed
    }

    var sortedClips: [SongClip] {
        clips.sorted { $0.order < $1.order }
    }

    func touch() {
        updatedAt = .now
    }
}

@Model
final class SongClip {
    @Attribute(.unique) var id: UUID
    var fragmentID: UUID
    var titleSnapshot: String
    var categoryRaw: String
    var noteSnapshot: String
    var order: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        fragmentID: UUID,
        titleSnapshot: String,
        category: IdeaCategory,
        noteSnapshot: String = "",
        order: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.fragmentID = fragmentID
        self.titleSnapshot = titleSnapshot
        self.categoryRaw = category.rawValue
        self.noteSnapshot = noteSnapshot
        self.order = order
        self.createdAt = createdAt
    }

    var category: IdeaCategory {
        IdeaCategory(rawValue: categoryRaw) ?? .riff
    }
}

// MARK: - Export

enum DraftExport {
    static func text(for draft: SongDraft) -> String {
        var lines: [String] = []
        lines.append("# \(draft.displayTitle)")
        lines.append("")
        lines.append("Key: \(draft.keyCenter.isEmpty ? "Not set" : draft.keyCenter)")
        lines.append("Tempo: \(draft.bpm > 0 ? "\(draft.bpm) BPM" : "Not set")")

        if !draft.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("")
            lines.append("Notes: \(draft.note)")
        }

        for section in draft.sortedSections {
            lines.append("")
            lines.append("## \(section.displayTitle) [\(section.kind.label)]")

            if !section.chords.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                lines.append("Chords: \(section.chords)")
            }

            if !section.lyricNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                lines.append("")
                lines.append(section.lyricNotes)
            }

            if !section.sortedClips.isEmpty {
                lines.append("")
                lines.append("Attached ideas:")
                for clip in section.sortedClips {
                    lines.append("- \(clip.titleSnapshot) (\(clip.category.label))")
                }
            }
        }

        return lines.joined(separator: "\n")
    }
}

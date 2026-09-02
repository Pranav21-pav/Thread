import SwiftUI

struct CategoryBadge: View {
    let category: IdeaCategory

    var body: some View {
        Label(category.label, systemImage: category.systemImage)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial, in: Capsule())
    }
}

struct MetadataLine: View {
    let idea: MusicIdea

    var body: some View {
        HStack(spacing: 8) {
            if !idea.instrument.isEmpty {
                Label(idea.instrument, systemImage: "music.note")
            }
            if !idea.keyCenter.isEmpty {
                Label(idea.keyCenter, systemImage: "key")
            }
            if idea.bpm > 0 {
                Label("\(idea.bpm) BPM", systemImage: "metronome")
            }
            if idea.hasAudio {
                Image(systemName: "waveform")
                    .accessibilityLabel("Has recording")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text(message))
    }
}

struct RecordingButton: View {
    let isRecording: Bool
    let elapsedTime: TimeInterval
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 34))
                VStack(alignment: .leading) {
                    Text(isRecording ? "Stop Recording" : "Record an Idea")
                        .font(.headline)
                    Text(isRecording ? elapsedTime.formattedRecordingTime : "Optional audio memo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct ChordChip: View {
    let chord: String
    let role: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(chord)
                    .font(.headline)
                Text(role)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 42)
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

extension TimeInterval {
    var formattedRecordingTime: String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension Date {
    var compactRelativeDescription: String {
        RelativeDateTimeFormatter().localizedString(for: self, relativeTo: .now)
    }
}

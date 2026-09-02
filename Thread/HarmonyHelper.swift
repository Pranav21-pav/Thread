import Foundation

enum HarmonyHelper {
    static let supportedKeys = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]

    private static let diatonicMajor: [String: [String]] = [
        "C":  ["C", "Dm", "Em", "F", "G", "Am", "Bdim"],
        "Db": ["Db", "Ebm", "Fm", "Gb", "Ab", "Bbm", "Cdim"],
        "D":  ["D", "Em", "F#m", "G", "A", "Bm", "C#dim"],
        "Eb": ["Eb", "Fm", "Gm", "Ab", "Bb", "Cm", "Ddim"],
        "E":  ["E", "F#m", "G#m", "A", "B", "C#m", "D#dim"],
        "F":  ["F", "Gm", "Am", "Bb", "C", "Dm", "Edim"],
        "F#": ["F#", "G#m", "A#m", "B", "C#", "D#m", "E#dim"],
        "G":  ["G", "Am", "Bm", "C", "D", "Em", "F#dim"],
        "Ab": ["Ab", "Bbm", "Cm", "Db", "Eb", "Fm", "Gdim"],
        "A":  ["A", "Bm", "C#m", "D", "E", "F#m", "G#dim"],
        "Bb": ["Bb", "Cm", "Dm", "Eb", "F", "Gm", "Adim"],
        "B":  ["B", "C#m", "D#m", "E", "F#", "G#m", "A#dim"]
    ]

    static func diatonicChords(for key: String) -> [String] {
        diatonicMajor[key] ?? diatonicMajor["C"] ?? []
    }

    static func colorChords(for key: String) -> [String] {
        let chords = diatonicChords(for: key)
        guard chords.count == 7 else { return [] }

        let tonic = chords[0]
        let majorTwo = chords[1].replacingOccurrences(of: "m", with: "")
        let minorFour = chords[3] + "m"
        let flatSeven = flattenedRoot(from: tonic)

        return [minorFour, majorTwo, flatSeven]
    }

    static func label(forDiatonicIndex index: Int) -> String {
        ["I", "ii", "iii", "IV", "V", "vi", "vii°"][index]
    }

    static func label(forColorIndex index: Int) -> String {
        ["iv", "II", "♭VII"][index]
    }

    private static func flattenedRoot(from tonic: String) -> String {
        let chromatic = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
        let enharmonic: [String: String] = ["F#": "Gb"]
        let normalized = enharmonic[tonic] ?? tonic
        guard let index = chromatic.firstIndex(of: normalized) else { return "Bb" }
        return chromatic[(index + 10) % 12]
    }
}

enum CompositionCoach {
    static let prompts = [
        "Repeat the last two notes of a melody, then answer them one scale step higher.",
        "Try the minor iv chord before returning to I for a bittersweet lift.",
        "Write a four-line verse where the final line is noticeably shorter.",
        "Move a riff to another instrument: hum it, play it on guitar, then try it on saxophone.",
        "Keep the verse progression, but change the harmonic rhythm in the chorus.",
        "Use a major II chord as a brief push toward V.",
        "Take one lyric image and replace the abstract emotion with a physical object in the room.",
        "Record one imperfect take immediately. Edit only after you have something audible.",
        "Write an interlude that quotes the vocal melody but changes its ending.",
        "Try a short borrowed ♭VII chord before IV or I."
    ]

    static func prompt(for date: Date = .now) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        return prompts[(day - 1) % prompts.count]
    }
}

# Thread — SwiftUI Music Idea Notebook

Thread is a runnable iOS 17+ SwiftUI MVP for capturing musical ideas and composing song structures on the go.

## Included features

- One-tap local audio recording with microphone permission handling
- Text capture for lyrics, riffs, chord loops, rhythm notes, song sections, and practice takes
- Searchable idea library with category filtering
- Editable idea details, favorites, tags, key, tempo, and instrument metadata
- Daily resurfacing of older fragments and simple compatibility suggestions
- Song drafts with ordered intro / verse / chorus / bridge / interlude / solo / outro sections
- Per-section lyric notebook and chord scratchpad
- Tap-to-append diatonic chord palette and a small set of borrowed “color chords”
- Attach saved ideas to any song section
- Export a song draft as structured plain text using the iOS share sheet
- Fully local storage using SwiftData; no external packages or APIs

## Open and run

1. 1Unzip the folder.
2. 2Open `Thread.xcodeproj` in Xcode.
3. 3Select the `Thread` target.
4. 4Under **Signing & Capabilities**, choose your Apple Developer team.
5. 5Change the bundle identifier if Xcode reports that `com.pranav.threadmusicapp` is unavailable.
6. 6Choose an iPhone simulator or a physical iPhone and press Run.

Audio recording is most useful on a physical device. The project includes the required microphone usage description in its build settings.

## Files

- `ThreadApp.swift`: app entry point and SwiftData container
- `Models.swift`: persistent models and text export
- `AudioServices.swift`: local audio recording and playback
- `HarmonyHelper.swift`: chord palette and composition prompts
- `HomeView.swift`: daily resurfacing and quick capture entry point
- `QuickCaptureView.swift`: audio / text idea capture
- `LibraryView.swift`: searchable idea library
- `IdeaDetailView.swift`: edit, play, favorite, and delete an idea
- `ComposerView.swift`: song draft list and creation sheet
- `DraftEditorView.swift`: mobile composition board, section editor, chord palette, and idea attachment
- `SettingsView.swift`: local-storage explanation and usage guide

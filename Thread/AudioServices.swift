import Foundation
import AVFoundation
import Combine

// MARK: - Shared Audio File Storage

enum AudioFileStore {
    static func recordingsDirectory() throws -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directory = documents.appendingPathComponent("Recordings", isDirectory: true)

        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        return directory
    }

    static func url(for fileName: String) throws -> URL {
        try recordingsDirectory().appendingPathComponent(fileName)
    }

    static func delete(fileName: String?) {
        guard let fileName, !fileName.isEmpty else { return }
        guard let url = try? url(for: fileName) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Recording

@MainActor
final class AudioRecorderService: NSObject, ObservableObject, AVAudioRecorderDelegate {
    enum RecorderError: LocalizedError {
        case permissionDenied
        case couldNotStart

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Microphone access is required to record an idea. Enable it in Settings if it was previously denied."
            case .couldNotStart:
                return "The recording could not start."
            }
        }
    }

    @Published private(set) var isRecording = false
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published var errorMessage: String?

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private(set) var activeFileName: String?

    func startRecording() async {
        do {
            let granted = await AVAudioApplication.requestRecordPermission()
            guard granted else { throw RecorderError.permissionDenied }

            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)

            let fileName = "idea-\(UUID().uuidString).m4a"
            let url = try AudioFileStore.url(for: fileName)
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            let newRecorder = try AVAudioRecorder(url: url, settings: settings)
            newRecorder.delegate = self
            newRecorder.prepareToRecord()

            guard newRecorder.record() else {
                throw RecorderError.couldNotStart
            }

            recorder = newRecorder
            activeFileName = fileName
            elapsedTime = 0
            isRecording = true
            errorMessage = nil
            startTimer()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func stopRecording() -> String? {
        recorder?.stop()
        recorder = nil
        stopTimer()
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return activeFileName
    }

    func cancelRecording() {
        recorder?.stop()
        recorder = nil
        stopTimer()
        isRecording = false
        AudioFileStore.delete(fileName: activeFileName)
        activeFileName = nil
        elapsedTime = 0
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        stopTimer()
        isRecording = false
        if !flag {
            AudioFileStore.delete(fileName: activeFileName)
            activeFileName = nil
            errorMessage = "The recording did not save successfully."
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.elapsedTime = self.recorder?.currentTime ?? self.elapsedTime
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Playback

@MainActor
final class AudioPlayerService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var playingFileName: String?
    @Published private(set) var isPlaying = false
    @Published var errorMessage: String?

    private var player: AVAudioPlayer?

    func toggle(fileName: String) {
        if isPlaying, playingFileName == fileName {
            stop()
        } else {
            play(fileName: fileName)
        }
    }

    func play(fileName: String) {
        do {
            stop()
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            let url = try AudioFileStore.url(for: fileName)
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.delegate = self
            newPlayer.prepareToPlay()
            newPlayer.play()

            player = newPlayer
            playingFileName = fileName
            isPlaying = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stop() {
        player?.stop()
        player = nil
        playingFileName = nil
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stop()
    }
}


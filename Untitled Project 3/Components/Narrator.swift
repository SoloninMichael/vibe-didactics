import AVFoundation

/// Reads captions aloud with the on-device speech synthesizer.
final class Narrator {
    static let shared = Narrator()

    private let synthesizer = AVSpeechSynthesizer()
    private var configured = false

    func speak(_ text: String) {
        if !configured {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            configured = true
        }
        try? AVAudioSession.sharedInstance().setActive(true)
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.53
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    /// Rough speaking time, so a beat doesn't cut the narration off.
    static func estimatedDuration(_ text: String) -> Double {
        Double(text.split(separator: " ").count) / 2.6 + 0.6
    }
}

import AVFoundation
import Combine

@Observable
final class TTSService: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = TTSService()

    private let synthesizer = AVSpeechSynthesizer()
    var isSpeaking: Bool = false
    var isPaused: Bool = false
    var currentUtteranceIndex: Int = 0
    var totalUtterances: Int = 0
    var speechRate: Float = AVSpeechUtteranceDefaultSpeechRate
    var voice: AVSpeechSynthesisVoice?
    var onSpeakComplete: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
        voice = AVSpeechSynthesisVoice(language: "zh-CN")
            ?? AVSpeechSynthesisVoice.speechVoices().first(where: { $0.language.hasPrefix("zh") })
            ?? AVSpeechSynthesisVoice(language: "zh-Hans")
            ?? AVSpeechSynthesisVoice.speechVoices().first
    }

    func speak(text: String) {
        stop()

        let paragraphs = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        totalUtterances = paragraphs.count
        currentUtteranceIndex = 0

        guard !paragraphs.isEmpty else { return }

        isSpeaking = true
        isPaused = false

        for (index, paragraph) in paragraphs.enumerated() {
            let utterance = AVSpeechUtterance(string: paragraph)
            utterance.voice = voice
            utterance.rate = speechRate
            utterance.pitchMultiplier = 1.0
            utterance.volume = 1.0
            utterance.preUtteranceDelay = index == 0 ? 0 : 0.1
            synthesizer.speak(utterance)
        }
    }

    func pause() {
        guard isSpeaking && !isPaused else { return }
        synthesizer.pauseSpeaking(at: .immediate)
        isPaused = true
    }

    func resume() {
        guard isSpeaking && isPaused else { return }
        synthesizer.continueSpeaking()
        isPaused = false
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPaused = false
        currentUtteranceIndex = 0
        totalUtterances = 0
    }

    func setRate(_ rate: Float) {
        speechRate = min(max(rate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)
    }

    func nextSentence() {
        // Skip to next utterance (iOS doesn't directly support this,
        // but we can stop and restart from a different position)
    }

    func previousSentence() {
        // Similar limitation as above
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.currentUtteranceIndex += 1
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            if self?.currentUtteranceIndex >= self?.totalUtterances ?? 0 {
                self?.isSpeaking = false
                self?.isPaused = false
                self?.onSpeakComplete?()
            }
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = false
            self?.isPaused = false
        }
    }

    // MARK: - Available Voices

    var availableVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("zh") || $0.language.hasPrefix("en") || $0.language == "zh-CN" || $0.language == "zh-TW" || $0.language == "zh-Hans" || $0.language == "zh-Hant" }
    }

    func selectVoice(identifier: String?) {
        if let id = identifier {
            voice = AVSpeechSynthesisVoice(identifier: id)
        } else {
            voice = AVSpeechSynthesisVoice(language: "zh-CN") ?? AVSpeechSynthesisVoice.speechVoices().first
        }
    }
}

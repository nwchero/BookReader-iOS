import Foundation
import SwiftUI

enum ReaderBackgroundType: String, CaseIterable, Identifiable {
    case light = "护眼黄"
    case sepia = "羊皮纸"
    case green = "绿茵"
    case dark = "深色"
    case night = "夜间"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .light: return Color(hex: "F5F5DC")
        case .sepia: return Color(hex: "F4ECD8")
        case .green: return Color(hex: "CCE8CF")
        case .dark: return Color(hex: "1A1A2E")
        case .night: return Color.black
        }
    }

    var textColor: Color {
        switch self {
        case .night, .dark: return Color(hex: "B0B0B0")
        default: return Color(hex: "333333")
        }
    }
}

@Observable
final class ReaderViewModel {
    var bookTitle: String = ""
    var chapters: [Chapter] = []
    var currentChapterIndex: Int = 0
    var chapterContent: String = ""
    var chapterTitle: String = ""
    var isLoadingContent: Bool = false
    var showDirectory: Bool = false
    var showSettings: Bool = false
    var fontSize: Int = 18
    var lineHeightMultiplier: Float = 1.6
    var backgroundType: ReaderBackgroundType = .light
    var isNightMode: Bool = false

    // MARK: - TTS State
    var isTTSSpeaking: Bool = false
    var isTTSPaused: Bool = false
    var ttsSpeechRate: Float = AVSpeechUtteranceDefaultSpeechRate
    var showTTSControl: Bool = false

    private let bookUrl: String
    private let dataManager = DataManager.shared
    private let tts = TTSService.shared

    init(bookUrl: String, initialChapterIndex: Int = 0) {
        self.bookUrl = bookUrl
        self.currentChapterIndex = initialChapterIndex
        loadChapters()
    }

    func loadChapters() {
        chapters = dataManager.getChapters(forBookUrl: bookUrl)
        if !chapters.isEmpty() {
            let index = min(initialChapterIndex, chapters.count - 1)
            loadChapterContent(at: index)
        }
    }

    func loadChapterContent(at index: Int) {
        guard index >= 0, index < chapters.count else { return }

        stopTTS()

        isLoadingContent = true
        let chapter = chapters[index]

        Task { @MainActor in
            do {
                let sources = dataManager.getAllSources()
                for source in sources {
                    let parser = SourceParser(source: source)
                    if let content = try? await parser.getChapterContent(chapterUrl: chapter.url), !content.isEmpty {
                        self.chapterContent = content
                        self.chapterTitle = chapter.title
                        self.currentChapterIndex = index
                        self.isLoadingContent = false
                        dataManager.updateLastReadTime(bookUrl: bookUrl)
                        return
                    }
                }
                self.chapterContent = ""
                self.chapterTitle = chapter.title
                self.currentChapterIndex = index
                self.isLoadingContent = false
            } catch {
                self.chapterContent = "加载章节内容失败"
                self.chapterTitle = chapter.title
                self.currentChapterIndex = index
                self.isLoadingContent = false
            }
        }
    }

    func nextChapter() {
        let next = currentChapterIndex + 1
        if next < chapters.count {
            loadChapterContent(at: next)
        }
    }

    func prevChapter() {
        let prev = currentChapterIndex - 1
        if prev >= 0 {
            loadChapterContent(at: prev)
        }
    }

    func goToChapter(_ index: Int) {
        guard index >= 0, index < chapters.count else { return }
        loadChapterContent(at: index)
    }

    func toggleDirectory() {
        showDirectory.toggle()
        if showDirectory { showSettings = false; showTTSControl = false }
    }

    func toggleSettings() {
        showSettings.toggle()
        if showSettings { showDirectory = false; showTTSControl = false }
    }

    func increaseFontSize() {
        fontSize = min(fontSize + 2, 32)
    }

    func decreaseFontSize() {
        fontSize = max(fontSize - 2, 12)
    }

    func setLineHeight(_ multiplier: Float) {
        lineHeightMultiplier = min(max(multiplier, 1.2), 2.5)
    }

    func setBackgroundType(_ type: ReaderBackgroundType) {
        backgroundType = type
        isNightMode = (type == .night)
    }

    func toggleNightMode() {
        isNightMode.toggle()
        backgroundType = isNightMode ? .night : .light
    }

    func closeAllPanels() {
        showDirectory = false
        showSettings = false
        showTTSControl = false
    }

    // MARK: - TTS Methods

    func startTTS() {
        guard !chapterContent.isEmpty else { return }
        tts.speechRate = ttsSpeechRate
        tts.onSpeakComplete = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isTTSSpeaking = false
                self.isTTSPaused = false
            }
        }
        tts.speak(text: chapterContent)
        isTTSSpeaking = true
        isTTSPaused = false
        showTTSControl = true
        showDirectory = false
        showSettings = false
    }

    func pauseTTS() {
        tts.pause()
        isTTSPaused = true
    }

    func resumeTTS() {
        tts.resume()
        isTTSPaused = false
    }

    func stopTTS() {
        tts.stop()
        isTTSSpeaking = false
        isTTSPaused = false
    }

    func setTTSRate(_ rate: Float) {
        ttsSpeechRate = rate
        tts.setRate(rate)
    }

    func toggleTTSPanel() {
        showTTSControl.toggle()
        if showTTSControl {
            showDirectory = false
            showSettings = false
        }
    }
}

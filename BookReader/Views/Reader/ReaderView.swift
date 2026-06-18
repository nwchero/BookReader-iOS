import SwiftUI

struct ReaderView: View {
    let bookUrl: String
    let initialChapterIndex: Int
    @Binding var path: NavigationPath

    @State private var viewModel: ReaderViewModel
    @State private var showToolbar: Bool = false

    init(bookUrl: String, initialChapterIndex: Int = 0, path: Binding<NavigationPath>) {
        self.bookUrl = bookUrl
        self.initialChapterIndex = initialChapterIndex
        self._path = path
        _viewModel = State(initialValue: ReaderViewModel(bookUrl: bookUrl, initialChapterIndex: initialChapterIndex))
    }

    private var bgColor: Color { viewModel.backgroundType.color }
    private var textColor: Color { viewModel.backgroundType.textColor }

    var body: some View {
        ZStack(alignment: .top) {
            bgContent

            if showToolbar && !viewModel.showDirectory && !viewModel.showSettings && !viewModel.showTTSControl {
                readerToolbar
            }

            chapterNavBar

            if viewModel.showDirectory { directorySheet }
            if viewModel.showSettings { settingsSheet }
            if viewModel.showTTSControl { ttsControlPanel }

            // Floating TTS indicator when speaking but panel hidden
            if viewModel.isTTSSpeaking && !viewModel.showTTSControl && showToolbar {
                floatingTTSIndicator
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onTapGesture(count: 2) { }
        .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { showToolbar.toggle() } }
    }

    // MARK: - Background Content

    private var bgContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: CGFloat(viewModel.fontSize) * CGFloat(viewModel.lineHeightMultiplier) - CGFloat(viewModel.fontSize)) {
                    if !viewModel.chapterTitle.isEmpty {
                        Text(viewModel.chapterTitle)
                            .font(AppTheme.ReaderFont.title(size: CGFloat(viewModel.fontSize)))
                            .foregroundStyle(textColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .id("title")
                    }

                    if viewModel.isLoadingContent {
                        ProgressView().tint(textColor.opacity(0.6)).frame(maxWidth: .infinity).padding(60)
                    } else if !viewModel.chapterContent.isEmpty {
                        ForEach(Array(viewModel.chapterContent.components(separatedBy: "\n").enumerated()), id: \.offset) { _, paragraph in
                            let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                Text(trimmed)
                                    .font(AppTheme.ReaderFont.body(size: CGFloat(viewModel.fontSize)))
                                    .foregroundStyle(textColor)
                                    .lineSpacing(CGFloat(viewModel.fontSize) * CGFloat(viewModel.lineHeightMultiplier) - CGFloat(viewModel.fontSize))
                                    .textSelection(.enabled)
                                    .padding(.horizontal, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    } else {
                        Text("暂无内容").foregroundStyle(textColor.opacity(0.5)).frame(maxWidth: .infinity).padding(60)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 80)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.currentChapterIndex) { _, _ in withAnimation { proxy.scrollTo("title", anchor: .top) } }
        }
        .background(bgColor.ignoresSafeArea())
    }

    // MARK: - Toolbar (with TTS button)

    private var readerToolbar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Button(action: { path.removeLast() }) {
                    Image(systemName: "chevron.left").foregroundStyle(textColor)
                }

                Text(viewModel.bookTitle.ifEmpty("阅读中"))
                    .font(.headline).foregroundStyle(textColor).lineLimit(1)

                Spacer()

                Button(action: { viewModel.toggleTTSPanel() }) {
                    Image(systemName: viewModel.isTTSSpeaking ? "waveform" : "speaker.wave.2.fill")
                        .foregroundStyle(viewModel.isTTSSpeaking ? AppTheme.primary : textColor)
                }

                Button(action: { viewModel.toggleDirectory() }) {
                    Image(systemName: "list.bullet").foregroundStyle(textColor)
                }

                Button(action: { viewModel.toggleSettings() }) {
                    Image(systemName: "slider.horizontal.3").foregroundStyle(textColor)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(bgColor.opacity(showToolbar ? 0.95 : 0).ignoresSafeArea())
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Chapter Navigation Bar

    private var chapterNavBar: some View {
        VStack {
            Spacer()
            if showToolbar && !viewModel.isTTSSpeaking {
                HStack(spacing: 0) {
                    Button(action: viewModel.prevChapter) {
                        HStack(spacing: 4) {
                            Image(systemName: "backward.end.fill").font(.caption)
                            Text("上一章").font(.subheadline)
                        }.foregroundStyle(textColor)
                        .opacity(viewModel.currentChapterIndex > 0 ? 1 : 0.3)
                    }.disabled(viewModel.currentChapterIndex <= 0)

                    Spacer()
                    Text("\(viewModel.currentChapterIndex + 1) / \(viewModel.chapters.count)")
                        .font(.caption).foregroundStyle(textColor.opacity(0.7))
                    Spacer()

                    Button(action: viewModel.nextChapter) {
                        HStack(spacing: 4) {
                            Text("下一章").font(.subheadline)
                            Image(systemName: "forward.end.fill").font(.caption)
                        }.foregroundStyle(textColor)
                        .opacity(viewModel.currentChapterIndex < viewModel.chapters.count - 1 ? 1 : 0.3)
                    }.disabled(viewModel.currentChapterIndex >= viewModel.chapters.count - 1)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 0).fill(textColor.opacity(0.05)))
            }
        }
        .transition(.opacity)
    }

    // MARK: - Floating TTS Indicator

    private var floatingTTSIndicator: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Circle()
                    .fill(AppTheme.primary)
                    .frame(width: 8, height: 8)
                    .opacity(viewModel.isTTSPaused ? 0.3 : 1)

                Text(viewModel.isTTSPaused ? "已暂停" : "正在朗读...")
                    .font(.caption).foregroundStyle(textColor)

                Spacer()

                Button(action: { viewModel.toggleTTSPanel() }) {
                    Image(systemName: "chevron.up").font(.caption).foregroundStyle(textColor)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 20).fill(bgColor.opacity(0.9)).shadow(color: .black.opacity(0.1), radius: 4))
            .padding(.horizontal, 16).padding(.bottom, 8)
        }
    }

    // MARK: - Directory Sheet

    private var directorySheet: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { viewModel.closeAllPanels() }
            VStack(spacing: 0) {
                headerRow(title: "目录", subtitle: "\(viewModel.chapters.count) 章")
                Divider()
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.chapters.enumerated()), id: \.element.id) { index, chapter in
                            chapterRow(index: index, chapter: chapter)
                            if index < viewModel.chapters.count - 1 { Divider().padding(.leading, 66) }
                        }
                    }
                }.frame(maxHeight: UIScreen.main.bounds.height * 0.6)
            }
            .sheetBackground
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func chapterRow(index: Int, chapter: Chapter) -> some View {
        Button(action: { viewModel.goToChapter(index); viewModel.closeAllPanels() }) {
            HStack(spacing: 10) {
                Text("\(index + 1)").font(.caption).foregroundStyle(.tertiary).frame(width: 40, alignment: .trailing)
                Text(chapter.title).font(.subheadline)
                    .foregroundStyle(index == viewModel.currentChapterIndex ? AppTheme.primary : .primary)
                    .fontWeight(index == viewModel.currentChapterIndex ? .bold : .regular).lineLimit(1)
                Spacer()
                if index == viewModel.currentChapterIndex {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.primary).font(.system(size: 18))
                }
            }.padding(.horizontal, 16).padding(.vertical, 11).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    // MARK: - Settings Sheet

    private var settingsSheet: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { viewModel.closeAllPanels() }
            VStack(spacing: 20) {
                headerRow(title: "阅读设置", subtitle: nil)
                Divider()
                fontSizeControl
                lineHeightControl
                backgroundSelector
                Divider()
                nightModeToggle
            }.padding(.bottom, 30).sheetBackground
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - TTS Control Panel (语音朗读控制)

    private var ttsControlPanel: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { viewModel.closeAllPanels() }

            VStack(spacing: 18) {
                headerRow(title: "🎤 语音朗读", subtitle: viewModel.chapterTitle)

                Divider()

                // Playback Controls
                HStack(spacing: 24) {
                    Button(action: viewModel.stopTTS) {
                        VStack(spacing: 4) {
                            Image(systemName: "stop.fill").font(.title2)
                            Text("停止").font(.caption2)
                        }.foregroundStyle(.red)
                    }

                    Button(action: {
                        if viewModel.isTTSPaused { viewModel.resumeTTS() } else { viewModel.pauseTTS() }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: viewModel.isTTSPaused ? "play.circle.fill" : "pause.circle.fill")
                                .font(.largeTitle).foregroundStyle(AppTheme.primary)
                            Text(viewModel.isTTSPaused ? "继续" : "暂停").font(.caption2)
                        }
                    }

                    Button(action: {
                        if !viewModel.isTTSSpeaking { viewModel.startTTS() }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "speaker.wave.2.fill").font(.title2)
                                .foregroundStyle(!viewModel.isTTSSpeaking ? AppTheme.primary : .secondary)
                            Text("朗读本章").font(.caption2)
                        }
                    }.disabled(viewModel.chapterContent.isEmpty || viewModel.isTTSSpeaking)
                }
                .padding(.vertical, 8)

                // Speed Control
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("语速")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text(speedLabel)
                            .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.ttsSpeechRate) },
                            set: { viewModel.setTTSRate(Float($0)) }
                        ),
                        in: 0.1...1.0,
                        step: 0.05
                    ).tint(AppTheme.primary)
                }
                .padding(.horizontal, 16)

                Divider()

                // Auto-next chapter option
                HStack(spacing: 12) {
                    Image(systemName: "arrow.forward.circle").foregroundStyle(AppTheme.primary).frame(width: 22)
                    Text("朗读完自动翻到下一章").font(.body)
                    Spacer()
                    // Toggle for auto-advance could go here
                    Image(systemName: "info.circle").font(.caption).foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 34).sheetBackground
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var speedLabel: String {
        let rate = Double(viewModel.ttsSpeechRate)
        let defaultRate = Double(AVSpeechUtteranceDefaultSpeechRate)
        switch rate {
        case ..<0.25: return "很慢"
        case 0.25..<0.4: return "慢"
        case 0.4..<0.5: return "较慢"
        case 0.5..<defaultRate: return "正常偏慢"
        case defaultRate...defaultRate: return "正常"
        case (defaultRate + 0.01)...0.65: return "正常偏快"
        case 0.65..<0.8: return "较快"
        default: return "快"
        }
    }

    // MARK: - Shared Components

    private func headerRow(title: String, subtitle: String?) -> some View {
        HStack {
            Text(title).font(.title2.bold())
            Spacer()
            if let sub = subtitle {
                Text(sub).font(.caption).foregroundStyle(.secondary)
            }
        }.padding(.horizontal, 16).padding(.vertical, 14)
    }

    // MARK: - Font Size Control

    private var fontSizeControl: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("字号").font(.subheadline.weight(.medium))
            HStack(spacing: 12) {
                Button(action: viewModel.decreaseFontSize) {
                    Image(systemName: "minus").frame(width: 36, height: 36).background(Color(.systemGray5)).clipShape(Circle())
                }
                Slider(value: Binding(get: { Double(viewModel.fontSize) }, set: { viewModel.fontSize = Int($0) }),
                       in: Double(AppTheme.ReaderFont.minSize)...Double(AppTheme.ReaderFont.maxSize), step: 2).tint(AppTheme.primary)
                Button(action: viewModel.increaseFontSize) {
                    Image(systemName: "plus").frame(width: 36, height: 36).background(Color(.systemGray5)).clipShape(Circle())
                }
                Text("\(viewModel.fontSize) sp").font(.caption.monospacedDigit()).foregroundStyle(.secondary).frame(width: 50)
            }
        }.padding(.horizontal, 16)
    }

    // MARK: - Line Height Control

    private var lineHeightControl: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("行距").font(.subheadline.weight(.medium))
            Slider(value: Binding(get: { Double(viewModel.lineHeightMultiplier) }, set: { viewModel.setLineHeight(Float($0)) }),
                   in: 1.2...2.5, step: 0.1).tint(AppTheme.primary)
        }.padding(.horizontal, 16)
    }

    // MARK: - Background Selector

    private var backgroundSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("背景颜色").font(.subheadline.weight(.medium))
            HStack(spacing: 12) {
                ForEach(ReaderBackgroundType.allCases) { type in
                    let isSelected = viewModel.backgroundType == type
                    Button(action: { viewModel.setBackgroundType(type) }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(type.color).frame(width: 52, height: 52)
                                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(isSelected ? AppTheme.primary : Color.clear, lineWidth: 2))
                            if isSelected { Image(systemName: "checkmark").foregroundStyle(type.textColor) }
                        }
                    }.buttonStyle(.plain)
                }
            }
        }.padding(.horizontal, 16)
    }

    // MARK: - Night Mode Toggle

    private var nightModeToggle: some View {
        HStack(spacing: 12) {
            Image(systemName: "moon.fill").foregroundStyle(.secondary).frame(width: 22)
            Text("夜间模式").font(.body)
            Spacer()
            Toggle("", isOn: Binding(get: { viewModel.isNightMode }, set: { _ in viewModel.toggleNightMode() })).tint(AppTheme.primary).labelsHidden()
        }.padding(.horizontal, 16)
    }
}

// MARK: - Helpers

private extension View {
    var sheetBackground: some View {
        self.background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 20, y: -5)
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String { isEmpty ? fallback : self }
}

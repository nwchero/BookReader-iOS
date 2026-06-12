import SwiftUI
import UniformTypeIdentifiers

struct SourcesView: View {
    @State private var viewModel = SourceViewModel()
    @State private var importService = SourceImportService()
    @State private var showAddSheet: Bool = false
    @State private var showImportSheet: Bool = false
    @State private var editingSource: BookSource?
    @State private var showFileImporter: Bool = false
    @State private var importURL: String = ""
    @State private var newName: String = ""
    @State private var newBaseUrl: String = ""
    @State private var newSearchUrl: String = ""
    @State private var newDetailUrl: String = ""
    @State private var newChapterUrl: String = ""
    @State private var newContentUrl: String = ""

    var body: some View {
        NavigationStack {
            Group {
                if importService.isImporting {
                    importProgressView
                } else if viewModel.isLoading {
                    ProgressView("加载中…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.sources.isEmpty {
                    emptySourcesView
                } else {
                    sourcesList
                }
            }
            .navigationTitle("书源管理")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { showAddSheet = true }) {
                            Label("手动添加", systemImage: "plus")
                        }
                        Button(action: { showImportSheet = true }) {
                            Label("导入书源", systemImage: "square.and.arrow.down")
                        }
                        Button(action: { Task { await importService.importDefaultSources() }}) {
                            Label("默认书源", systemImage: "star.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) { addSourceSheet }
            .sheet(isPresented: $showImportSheet) { importSheet }
            .sheet(item: $editingSource) { source in editSourceSheet(source) }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        Task { await importService.importFromLocalFile(url) }
                        viewModel.loadSources()
                    }
                case .failure(let error):
                    viewModel.message = "文件选择失败: \(error.localizedDescription)"
                @unknown default:
                    break
                }
            }
            .alert("提示", isPresented: Binding(
                get: { viewModel.message != nil || (importService.errorMessage != nil && !importService.isImporting) },
                set: { if !$0 { viewModel.message = nil; importService.errorMessage = nil } }
            )) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(viewModel.message ?? importService.errorMessage ?? "")
            }
        }
    }

    // MARK: - Import Progress

    private var importProgressView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView(value: importService.importProgress)
                .progressViewStyle(.circular)

            Text("正在导入书源...")
                .font(.headline)

            Text("\(importService.importedCount) / \(importService.totalSources)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if importService.importProgress >= 1.0 {
                Text("✅ 成功导入 \(importService.importedCount) 个书源")
                    .foregroundStyle(AppTheme.primary)
            }

            Spacer()

            Button("完成") { viewModel.loadSources() }
                .disabled(importService.isImporting)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Import Sheet

    private var importSheet: some View {
        NavigationStack {
            List {
                Section("网络导入") {
                    TextField("输入书源 JSON 地址", text: $importURL, prompt: Text("https://example.com/shuyuan.json"))
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)

                    Button(action: {
                        guard !importURL.isEmpty else { return }
                        Task { await importService.importFromURL(importURL); viewModel.loadSources() }
                    }) {
                        HStack {
                            Image(systemName: "network")
                            Text("从网络导入")
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }
                    }
                    .disabled(importURL.isEmpty || importService.isImporting)
                }

                Section("本地导入") {
                    Button(action: { showFileImporter = true }) {
                        HStack {
                            Image(systemName: "folder")
                            Text("选择 JSON 文件")
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }
                    }

                    Text("支持「阅读」App 格式的书源 JSON 文件")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("推荐书源地址") {
                    recommendedSourceRow(title: "XIU2 精品书源", url: "https://bitbucket.org/xiu2/yuedu/raw/master/shuyuan")
                    recommendedSourceRow(title: "大灰狼源合集 (12000+)", url: "http://mirror.ghproxy.com/https://raw.githubusercontent.com/shidahuilang/shuyuan/shuyuan/good.json")
                    recommendedSourceRow(title: "曦灵书源合集", url: "https://list.yiove.com/d/OpenFiles/share/shuyuan/20240805231826.json")

                    Text("点击即可快速填入，也可手动复制地址到上方输入框")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                }

                Section("导入记录") {
                    if importService.lastImportedSources.isEmpty {
                        Text("暂无导入记录").foregroundStyle(.secondary)
                    } else {
                        ForEach(importService.lastImportedSources.prefix(10), id: \.id) { source in
                            HStack(spacing: 8) {
                                Circle().fill(AppTheme.primary.opacity(0.15)).frame(width: 8, height: 8)
                                Text(source.name).lineLimit(1)
                                Spacer()
                                Text("已导入").font(.caption2).foregroundStyle(.green)
                            }.padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("导入书源")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { showImportSheet = false }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func recommendedSourceRow(title: String, url: String) -> some View {
        Button(action: { importURL = url }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).foregroundStyle(.primary)
                    Text(url.replacingOccurrences(of: "^https?://[^/]*//", with: ""))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "doc.badge.plus").foregroundStyle(AppTheme.primary)
            }
        }
    }

    // MARK: - Empty State

    private var emptySourcesView: some View {
        VStack(spacing: 24) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 80))
                .foregroundStyle(.secondary.opacity(0.3))
            Text("暂无书源")
                .font(.title3)
            Text("添加或导入书源即可搜索和阅读书籍")
                .font(.subheadline)
                .foregroundStyle(.secondary.opacity(0.7))

            HStack(spacing: 16) {
                Button("手动添加") { showAddSheet = true }
                    .buttonStyle(.borderedProminent)
                Button("导入书源") { showImportSheet = true }
                    .buttonStyle(.bordered)
                Button("默认书源") {
                    Task { await importService.importDefaultSources(); viewModel.loadSources() }
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Sources List

    private var sourcesList: some View {
        List {
            ForEach(viewModel.sources, id: \.id) { source in
                SourceRow(
                    source: source,
                    onEdit: { editingSource = source },
                    onToggle: { viewModel.toggleEnabled(source) }
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive, action: { viewModel.deleteSource(source) }) {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Add Source Sheet

    private var addSourceSheet: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("书源名称 *", text: $newName)
                    TextField("基础URL *", text: $newBaseUrl)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }
                Section("接口配置") {
                    TextField("搜索接口 *", text: $newSearchUrl)
                    TextField("详情接口", text: $newDetailUrl)
                    TextField("目录接口", text: $newChapterUrl)
                    TextField("正文接口", text: $newContentUrl)
                }
            }
            .navigationTitle("添加书源")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showAddSheet = false; resetFields() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let source = BookSource(
                            name: newName,
                            baseUrl: newBaseUrl,
                            searchUrl: newSearchUrl,
                            detailUrl: newDetailUrl.isEmpty ? "/book/{bookUrl}" : newDetailUrl,
                            chapterListUrl: newChapterUrl.isEmpty ? "/chapters/{bookUrl}" : newChapterUrl,
                            contentUrl: newContentUrl.isEmpty ? "/content/{chapterUrl}" : newContentUrl
                        )
                        viewModel.saveSource(source)
                        showAddSheet = false
                        resetFields()
                    }
                    .disabled(newName.isEmpty || newBaseUrl.isEmpty || newSearchUrl.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Edit Source Sheet

    private func editSourceSheet(_ source: BookSource) -> some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("书源名称", text: Binding(get: { source.name }, set: { source.name = $0 }))
                    TextField("基础URL", text: Binding(get: { source.baseUrl }, set: { source.baseUrl = $0 }))
                }
                Section("接口配置") {
                    TextField("搜索接口", text: Binding(get: { source.searchUrl }, set: { source.searchUrl = $0 }))
                    TextField("详情接口", text: Binding(get: { source.detailUrl }, set: { source.detailUrl = $0 }))
                    TextField("目录接口", text: Binding(get: { source.chapterListUrl }, set: { source.chapterListUrl = $0 }))
                    TextField("正文接口", text: Binding(get: { source.contentUrl }, set: { source.contentUrl = $0 }))
                }
            }
            .navigationTitle("编辑书源")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { editingSource = nil } }
                ToolbarItem(placement: .confirmationAction) { Button("保存") { viewModel.saveSource(source); editingSource = nil } }
            }
        }
        .presentationDetents([.large])
    }

    private func resetFields() {
        newName = ""; newBaseUrl = ""; newSearchUrl = ""
        newDetailUrl = ""; newChapterUrl = ""; newContentUrl = ""
    }
}

struct SourceRow: View {
    let source: BookSource
    let onEdit: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(source.name).font(.headline)
                    Text(source.isEnabled ? "启用" : "禁用")
                        .font(.caption2).fontWeight(.medium)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Capsule().fill(source.isEnabled ? AppTheme.primary.opacity(0.15) : Color.red.opacity(0.1)))
                        .foregroundStyle(source.isEnabled ? AppTheme.primary : .red)
                }
                Text(source.baseUrl).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Toggle("", isOn: Binding(get: { source.isEnabled }, set: { _ in onToggle() })).labelsHidden().tint(AppTheme.primary)
        }
        .contentShape(Rectangle())
        .onTapGesture { onEdit() }
        .padding(.vertical, 4)
    }
}

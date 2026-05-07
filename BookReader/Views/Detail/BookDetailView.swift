import SwiftUI

struct BookDetailView: View {
    let bookUrl: String
    @Binding var path: NavigationPath

    @State private var viewModel: BookDetailViewModel

    init(bookUrl: String, path: Binding<NavigationPath>) {
        self.bookUrl = bookUrl
        self._path = path
        _viewModel = State(initialValue: BookDetailViewModel(bookUrl: bookUrl))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("加载中…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let book = viewModel.book {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        bookHeaderSection(book)

                        Divider()

                        bookInfoSection(book)

                        if !viewModel.chapters.isEmpty || viewModel.isLoadingChapters {
                            Divider()
                            chapterListSection
                        }
                    }
                    .padding(16)
                }
            } else {
                ContentUnavailableView("无法加载", systemImage: "book.closed")
            }
        }
        .navigationTitle("书籍详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { viewModel.toggleBookshelf() }) {
                    Image(systemName: viewModel.isInBookshelf ? "heart.fill" : "heart")
                        .foregroundStyle(viewModel.isInBookshelf ? .red : AppTheme.primary)
                }
            }
        }
        .task { await viewModel.loadChapters() }
    }

    private func bookHeaderSection(_ book: Book) -> some View {
        HStack(alignment: .top, spacing: 16) {
            AsyncImage(url: URL(string: book.coverUrl)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    ZStack {
                        Color(.systemGray5)
                        Image(systemName: "book")
                            .font(.title2)
                            .foregroundStyle(.secondary.opacity(0.5))
                    }
                }
            }
            .frame(width: 100, height: 133)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.title2.bold())
                    .lineLimit(2)

                if !book.author.isEmpty {
                    Text("作者：\(book.author)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !book.category.isEmpty {
                    Text("分类：\(book.category)")
                        .captionRow
                }

                if !book.status.isEmpty {
                    Text("状态：\(book.status)")
                        .captionRow
                }

                if !book.latestChapter.isEmpty {
                    Text("最新：\(book.latestChapter)")
                        .captionRow
                        .lineLimit(1)
                }

                Spacer()

                Button(action: startReading) {
                    Label("开始阅读", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            Spacer()
        }
    }

    private func bookInfoSection(_ book: Book) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("简介")
                .font(.headline)

            if !book.descriptionText.isEmpty {
                Text(book.descriptionText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("暂无简介")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var chapterListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("目录")
                    .font(.headline)
                Text("(\(viewModel.chapters.count)章)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if viewModel.isLoadingChapters {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(Array(viewModel.chapters.enumerated()), id: \.element.id) { index, chapter in
                    Button(action: {
                        path.append(AppRoute.reader(bookUrl: bookUrl, chapterIndex: index))
                    }) {
                        HStack(spacing: 8) {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .frame(width: 36, alignment: .trailing)

                            Text(chapter.title)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.quaternary)
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func startReading() {
        path.append(AppRoute.reader(bookUrl: bookUrl, chapterIndex: 0))
    }
}

private extension View {
    var captionRow: some View {
        font(.caption).foregroundStyle(.secondary)
    }
}

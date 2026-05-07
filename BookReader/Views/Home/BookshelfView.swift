import SwiftUI

struct BookshelfView: View {
    @State private var viewModel = BookshelfViewModel()
    @State private var showSearch: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredBooks.isEmpty {
                    emptyBookshelfView
                } else {
                    bookGridView
                }
            }
            .navigationTitle("书架")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { showSearch.toggle() }) {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                }
            }
            .searchable(text: $viewModel.searchQuery, prompt: "搜索书架中的书籍…")
            .onChange(of: viewModel.searchQuery) { _, newValue in
                viewModel.searchBooks(newValue)
            }
        }
    }

    private var emptyBookshelfView: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 80))
                .foregroundStyle(.secondary.opacity(0.3))
            Text("书架空空如也")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("去发现好书吧")
                .font(.subheadline)
                .foregroundStyle(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var bookGridView: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                spacing: 16,
                content: {
                    ForEach(viewModel.filteredBooks, id: \.bookUrl) { book in
                        NavigationLink(value: AppRoute.bookDetail(bookUrl: book.bookUrl)) {
                            bookCard(book)
                        }
                        .buttonStyle(.plain)
                    }
                })
                .padding(16)
        }
    }

    private func bookCard(_ book: Book) -> some View {
        VStack(spacing: 6) {
            AsyncImage(url: URL(string: book.coverUrl)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    bookPlaceholder
                default:
                    bookPlaceholder
                }
            }
            .frame(width: (UIScreen.main.bounds.width - 56) / 3, height: ((UIScreen.main.bounds.width - 56) / 3) * 4 / 3)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4), lineWidth: 0.5))

            Text(book.title)
                .font(.caption)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !book.author.isEmpty {
                Text(book.author)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var bookPlaceholder: some View {
        ZStack {
            Color(.systemGray6)
            Image(systemName: "book")
                .font(.title2)
                .foregroundStyle(.secondary.opacity(0.5))
        }
    }
}

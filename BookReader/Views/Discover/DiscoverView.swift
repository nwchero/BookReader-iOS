import SwiftUI

struct DiscoverView: View {
    @State private var viewModel = DiscoverViewModel()
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sourceChips

                searchArea

                Group {
                    if viewModel.isLoading {
                        ProgressView("加载中…")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = viewModel.errorMessage {
                        errorView(error)
                    } else if !viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                        searchResultsList
                    } else if !viewModel.searchQuery.isEmpty && viewModel.searchResults.isEmpty {
                        emptyResultView
                    } else {
                        discoverPlaceholder
                    }
                }
            }
            .navigationTitle("发现")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var sourceChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.sources, id: \.id) { source in
                    PillChip(
                        title: source.name,
                        isSelected: viewModel.selectedSourceId == source.id,
                        action: { viewModel.selectSource(id: source.id) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var searchArea: some View {
        HStack(spacing: 10) {
            TextField("搜索书籍…", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    Task { await viewModel.searchBooks(searchText) }
                }

            Button(action: {
                Task { await viewModel.searchBooks(searchText) }
            }) {
                if viewModel.isSearching {
                    ProgressView()
                        .frame(maxWidth: 28, maxHeight: 28)
                } else {
                    Text("搜索")
                        .fontWeight(.medium)
                }
            }
            .disabled(searchText.isEmpty || viewModel.isSearching)
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var searchResultsList: some View {
        List(viewModel.searchResults, id: \.bookUrl) { book in
            NavigationLink(value: AppRoute.bookDetail(bookUrl: book.bookUrl)) {
                bookSearchRow(book)
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
    }

    private func bookSearchRow(_ book: Book) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: book.coverUrl)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    ZStack {
                        Color(.systemGray5)
                        Image(systemName: "book")
                            .foregroundStyle(.secondary.opacity(0.5))
                    }
                }
            }
            .frame(width: 56, height: 75)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 3) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(1)

                if !book.author.isEmpty {
                    Text("作者：\(book.author)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if !book.descriptionText.isEmpty {
                    Text(book.descriptionText)
                        .font(.caption)
                        .foregroundStyle(.secondary.opacity(0.7))
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    private var emptyResultView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary.opacity(0.3))
            Text("未找到相关书籍")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var discoverPlaceholder: some View {
        VStack(spacing: 20) {
            Image(systemName: "compass.drawing")
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.primary.opacity(0.4))
            Text("发现好书")
                .font(.title3)
            Text("输入关键词搜索你喜欢的书籍")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.red)
            Text(message)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct PillChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? AppTheme.primary : Color(.systemGray5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(isSelected ? AppTheme.primary : Color(.systemGray4), lineWidth: isSelected ? 0 : 0.5)
                )
        }
        .buttonStyle(.plain)
    }
}

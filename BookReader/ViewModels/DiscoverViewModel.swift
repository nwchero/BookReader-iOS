import Foundation
import SwiftUI

@Observable
final class DiscoverViewModel {
    var sources: [BookSource] = []
    var selectedSourceId: UUID?
    var searchQuery: String = ""
    var searchResults: [Book] = []
    var isSearching: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?

    private let dataManager = DataManager.shared

    init() {
        loadSources()
    }

    func loadSources() {
        isLoading = true
        sources = dataManager.getAllSources()
        if let first = sources.first {
            selectedSourceId = first.id
        }
        isLoading = false
    }

    func selectSource(id: UUID) {
        selectedSourceId = id
        searchResults = []
    }

    func searchBooks(_ keyword: String) async {
        guard !keyword.isEmpty else { return }
        searchQuery = keyword
        isSearching = true
        errorMessage = nil

        do {
            guard let sourceId = selectedSourceId,
                  let source = dataManager.getSourceById(id: sourceId) else {
                throw NSError(domain: "Discover", code: -1, userInfo: [NSLocalizedDescriptionKey: "请选择书源"])
            }

            let parser = SourceParser(source: source)
            var results = try await parser.searchBooks(keyword: keyword)

            for (index, var book) in results.enumerated() {
                book.sourceName = source.name
                results[index] = book
            }

            for var result in results {
                if dataManager.getBook(byUrl: result.bookUrl) != nil {
                    result.isAddedToBookshelf = true
                    if let idx = searchResults.firstIndex(where: { $0.bookUrl == result.bookUrl }) {
                        searchResults[idx] = result
                    }
                }
            }

            self.searchResults = results
        } catch {
            errorMessage = error.localizedDescription
        }

        isSearching = false
    }

    func addToBookshelf(bookUrl: String) {
        dataManager.addToBookshelf(bookUrl: bookUrl)
        if let idx = searchResults.firstIndex(where: { $0.bookUrl == bookUrl }) {
            searchResults[idx].isAddedToBookshelf = true
        }
    }

    func getBookDetail(bookUrl: String) async -> Book? {
        guard let sourceId = selectedSourceId,
              let source = dataManager.getSourceById(id: sourceId) else {
            return dataManager.getBook(byUrl: bookUrl)
        }

        do {
            let parser = SourceParser(source: source)
            let book = try await parser.getBookDetail(bookUrl: bookUrl)
            dataManager.saveBook(book)
            return book
        } catch {
            return dataManager.getBook(byUrl: bookUrl)
        }
    }
}

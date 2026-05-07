import Foundation
import SwiftUI

@Observable
final class BookDetailViewModel {
    var book: Book?
    var chapters: [Chapter] = []
    var isLoading: Bool = false
    var isLoadingChapters: Bool = false
    var isInBookshelf: Bool = false

    private let bookUrl: String
    private let dataManager = DataManager.shared

    init(bookUrl: String) {
        self.bookUrl = bookUrl
        loadBookDetail()
    }

    func loadBookDetail() {
        isLoading = true
        if let existing = dataManager.getBook(byUrl: bookUrl) {
            self.book = existing
            self.isInBookshelf = existing.isAddedToBookshelf
        } else {
            self.book = Book(bookUrl: bookUrl, title: "未知书籍")
        }
        isLoading = false
    }

    func loadChapters() async {
        isLoadingChapters = true
        var result = dataManager.getChapters(forBookUrl: bookUrl)

        if result.isEmpty, let sourceId = book?.sourceId {
            if let source = dataManager.getSourceById(id: sourceId) {
                do {
                    let parser = SourceParser(source: source)
                    result = try await parser.getChapterList(bookUrl: bookUrl)
                    if !result.isEmpty {
                        dataManager.saveChapters(result)
                    }
                } catch {}
            }
        }

        chapters = result
        isLoadingChapters = false
    }

    func toggleBookshelf() {
        guard let book = book else { return }
        isInBookshelf.toggle()
        if isInBookshelf {
            dataManager.addToBookshelf(bookUrl: bookUrl)
        } else {
            dataManager.removeFromBookshelf(bookUrl: bookUrl)
        }
    }
}

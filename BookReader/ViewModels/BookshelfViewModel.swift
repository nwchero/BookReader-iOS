import Foundation
import SwiftUI

@Observable
final class BookshelfViewModel {
    var books: [Book] = []
    var filteredBooks: [Book] = []
    var searchQuery: String = ""
    var isLoading: Bool = false

    private let dataManager = DataManager.shared

    init() {
        loadBooks()
    }

    func loadBooks() {
        isLoading = true
        books = dataManager.getBookshelfBooks()
        filteredBooks = books
        isLoading = false
    }

    func searchBooks(_ query: String) {
        searchQuery = query
        if query.isEmpty {
            filteredBooks = books
        } else {
            filteredBooks = dataManager.searchInBookshelf(query: query)
        }
    }

    func removeFromBookshelf(bookUrl: String) {
        dataManager.removeFromBookshelf(bookUrl: bookUrl)
        loadBooks()
    }
}

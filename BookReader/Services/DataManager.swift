import Foundation
import SwiftData

@Observable
final class DataManager {
    static let shared = DataManager()

    var modelContext: ModelContext?

    private init() {}

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - BookSource CRUD

    func getAllSources() -> [BookSource] {
        let descriptor = FetchDescriptor<BookSource>(
            predicate: #Predicate { $0.isEnabled },
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        )
        return (try? modelContext?.fetch(descriptor)) ?? []
    }

    func getAllSourcesIncludingDisabled() -> [BookSource] {
        let descriptor = FetchDescriptor<BookSource>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        )
        return (try? modelContext?.fetch(descriptor)) ?? []
    }

    func getSourceById(id: UUID) -> BookSource? {
        let targetId = id
        let descriptor = FetchDescriptor<BookSource>(predicate: #Predicate { $0.id == targetId })
        return try? modelContext?.fetch(descriptor).first
    }

    func saveSource(_ source: BookSource) {
        modelContext?.insert(source)
        do { try modelContext?.save() } catch { print("Save source error: \(error)") }
    }

    func deleteSource(_ source: BookSource) {
        modelContext?.delete(source)
        do { try modelContext?.save() } catch { print("Delete source error: \(error)") }
    }

    // MARK: - Book CRUD

    func getBookshelfBooks() -> [Book] {
        let descriptor = FetchDescriptor<Book>(
            predicate: #Predicate { $0.isAddedToBookshelf },
            sortBy: [SortDescriptor(\.lastReadTime, order: .reverse)]
        )
        return (try? modelContext?.fetch(descriptor)) ?? []
    }

    func getBook(byUrl url: String) -> Book? {
        let targetUrl = url
        let descriptor = FetchDescriptor<Book>(predicate: #Predicate { $0.bookUrl == targetUrl })
        return try? modelContext?.fetch(descriptor).first
    }

    func searchInBookshelf(query: String) -> [Book] {
        let searchQuery = query
        let descriptor = FetchDescriptor<Book>(
            predicate: #Predicate { $0.title.localizedStandardContains(searchQuery) || $0.author.localizedStandardContains(searchQuery) }
        )
        return (try? modelContext?.fetch(descriptor)) ?? []
    }

    func saveBook(_ book: Book) {
        if let existing = getBook(byUrl: book.bookUrl) {
            existing.title = book.title
            existing.author = book.author
            existing.coverUrl = book.coverUrl
            existing.descriptionText = book.descriptionText
            existing.category = book.category
            existing.status = book.status
            existing.latestChapter = book.latestChapter
            existing.sourceName = book.sourceName
        } else {
            modelContext?.insert(book)
        }
        do { try modelContext?.save() } catch { print("Save book error: \(error)") }
    }

    func addToBookshelf(bookUrl: String) {
        guard let book = getBook(byUrl: bookUrl) else { return }
        book.isAddedToBookshelf = true
        book.lastReadTime = Date()
        do { try modelContext?.save() } catch {}
    }

    func removeFromBookshelf(bookUrl: String) {
        guard let book = getBook(byUrl: bookUrl) else { return }
        book.isAddedToBookshelf = false
        do { try modelContext?.save() } catch {}
    }

    func updateLastReadTime(bookUrl: String) {
        guard let book = getBook(byUrl: bookUrl) else { return }
        book.lastReadTime = Date()
        do { try modelContext?.save() } catch {}
    }

    // MARK: - Chapter CRUD

    func getChapters(forBookUrl bookUrl: String) -> [Chapter] {
        let targetBookUrl = bookUrl
        let descriptor = FetchDescriptor<Chapter>(
            predicate: #Predicate { $0.bookUrl == targetBookUrl },
            sortBy: [SortDescriptor(\.order)]
        )
        return (try? modelContext?.fetch(descriptor)) ?? []
    }

    func saveChapters(_ chapters: [Chapter]) {
        if let first = chapters.first {
            let firstBookUrl = first.bookUrl
            let existingDescriptor = FetchDescriptor<Chapter>(predicate: #Predicate { $0.bookUrl == firstBookUrl })
            if let existing = try? modelContext?.fetch(existingDescriptor) {
                for item in existing {
                    modelContext?.delete(item)
                }
            }
        }
        for chapter in chapters {
            modelContext?.insert(chapter)
        }
        do { try modelContext?.save() } catch {}
    }

    // MARK: - ReadingProgress

    func getReadingProgress(forBookUrl bookUrl: String) -> ReadingProgress? {
        let targetBookUrl = bookUrl
        let descriptor = FetchDescriptor<ReadingProgress>(predicate: #Predicate { $0.bookUrl == targetBookUrl })
        return try? modelContext?.fetch(descriptor).first
    }

    func saveReadingProgress(_ progress: ReadingProgress) {
        if let existing = getReadingProgress(forBookUrl: progress.bookUrl) {
            existing.chapterId = progress.chapterId
            existing.chapterTitle = progress.chapterTitle
            existing.chapterUrl = progress.chapterUrl
            existing.progress = progress.progress
            existing.updatedAt = Date()
        } else {
            modelContext?.insert(progress)
        }
        do { try modelContext?.save() } catch {}
    }
}

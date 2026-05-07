import Foundation
import SwiftData

@Model
final class Book {
    var bookUrl: String
    var title: String = ""
    var author: String = ""
    var coverUrl: String = ""
    var descriptionText: String = ""
    var category: String = ""
    var status: String = ""
    var latestChapter: String = ""
    var sourceId: UUID?
    var sourceName: String = ""
    var isAddedToBookshelf: Bool = false
    var lastReadTime: Date = Date.distantPast
    var createdAt: Date = Date()

    init(bookUrl: String, title: String = "", author: String = "") {
        self.bookUrl = bookUrl
        self.title = title
        self.author = author
    }
}

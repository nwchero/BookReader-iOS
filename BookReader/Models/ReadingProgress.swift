import Foundation
import SwiftData

@Model
final class ReadingProgress {
    var bookUrl: String
    var chapterId: UUID?
    var chapterTitle: String = ""
    var chapterUrl: String = ""
    var progress: Int = 0
    var updatedAt: Date = Date()

    init(bookUrl: String) {
        self.bookUrl = bookUrl
    }
}

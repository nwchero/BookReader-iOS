import Foundation
import SwiftData

@Model
final class Chapter {
    var id: UUID = UUID()
    var bookUrl: String
    var title: String
    var url: String
    var order: Int = 0

    init(bookUrl: String, title: String, url: String, order: Int = 0) {
        self.bookUrl = bookUrl
        self.title = title
        self.url = url
        self.order = order
    }
}

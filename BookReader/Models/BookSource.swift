import Foundation
import SwiftData

@Model
final class BookSource {
    var id: UUID = UUID()
    var name: String
    var baseUrl: String
    var searchUrl: String
    var detailUrl: String
    var chapterListUrl: String
    var contentUrl: String
    var searchMethod: String = "GET"
    var isEnabled: Bool = true
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    init(name: String, baseUrl: String, searchUrl: String, detailUrl: String = "", chapterListUrl: String = "", contentUrl: String = "") {
        self.name = name
        self.baseUrl = baseUrl
        self.searchUrl = searchUrl
        self.detailUrl = detailUrl
        self.chapterListUrl = chapterListUrl
        self.contentUrl = contentUrl
    }
}

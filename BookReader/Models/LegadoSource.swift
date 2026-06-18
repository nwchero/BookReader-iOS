import Foundation

struct LegadoSource: Codable, Identifiable {
    let id: UUID
    let bookSourceComment: String?
    let bookSourceGroup: String?
    let bookSourceName: String
    let bookSourceType: Int
    let bookSourceUrl: String
    let bookUrlPattern: String?
    let enabled: Bool
    let header: [String: String]?
    let ruleSearch: LegadoRule?
    let ruleBookInfo: LegadoRule?
    let ruleToc: LegadoRule?
    let ruleContent: LegadoContentRule?

    var searchUrl: String?
    var respondTime: Int?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case bookSourceComment, bookSourceGroup, bookSourceName, bookSourceType
        case bookSourceUrl, bookUrlPattern, customOrder
        case enabled, enabledCookieJar, enabledExplore
        case exploreUrl, header, lastUpdateTime, loginUrl, respondTime
        case ruleBookInfo, ruleContent, ruleExplore, ruleSearch, ruleToc
        case searchUrl, weight
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.bookSourceComment = try container.decodeIfPresent(String.self, forKey: .bookSourceComment)
        self.bookSourceGroup = try container.decodeIfPresent(String.self, forKey: .bookSourceGroup)
        self.bookSourceName = try container.decode(String.self, forKey: .bookSourceName)
        self.bookSourceType = try container.decodeIfPresent(Int.self, forKey: .bookSourceType) ?? 0
        self.bookSourceUrl = try container.decode(String.self, forKey: .bookSourceUrl)
        self.bookUrlPattern = try container.decodeIfPresent(String.self, forKey: .bookUrlPattern)
        self.enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        self.header = try container.decodeIfPresent([String: String].self, forKey: .header)
        self.ruleSearch = try container.decodeIfPresent(LegadoRule.self, forKey: .ruleSearch)
        self.ruleBookInfo = try container.decodeIfPresent(LegadoRule.self, forKey: .ruleBookInfo)
        self.ruleToc = try container.decodeIfPresent(LegadoRule.self, forKey: .ruleToc)
        self.ruleContent = try container.decodeIfPresent(LegadoContentRule.self, forKey: .ruleContent)
        self.searchUrl = try container.decodeIfPresent(String.self, forKey: .searchUrl)
        self.respondTime = try container.decodeIfPresent(Int.self, forKey: .respondTime)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(bookSourceComment, forKey: .bookSourceComment)
        try container.encodeIfPresent(bookSourceGroup, forKey: .bookSourceGroup)
        try container.encode(bookSourceName, forKey: .bookSourceName)
        try container.encode(bookSourceType, forKey: .bookSourceType)
        try container.encode(bookSourceUrl, forKey: .bookSourceUrl)
        try container.encodeIfPresent(bookUrlPattern, forKey: .bookUrlPattern)
        try container.encode(enabled, forKey: .enabled)
        try container.encodeIfPresent(header, forKey: .header)
        try container.encodeIfPresent(ruleSearch, forKey: .ruleSearch)
        try container.encodeIfPresent(ruleBookInfo, forKey: .ruleBookInfo)
        try container.encodeIfPresent(ruleToc, forKey: .ruleToc)
        try container.encodeIfPresent(ruleContent, forKey: .ruleContent)
        try container.encodeIfPresent(searchUrl, forKey: .searchUrl)
        try container.encodeIfPresent(respondTime, forKey: .respondTime)
    }
}

struct LegadoRule: Codable {
    var url: String?
    var list: String?
    var name: String?
    var author: String?
    var cover: String?
    var intro: String?
    var kind: String?
    var lastChapter: String?
    var wordCount: String?
    var tocUrl: String?

    enum CodingKeys: String, CodingKey {
        case url, list, name, author, cover, intro, kind
        case lastChapter, wordCount, tocUrl
    }
}

struct LegadoContentRule: Codable {
    var content: String?
    var nextContentUrl: String?
    var replaceRegex: [[String]]?

    enum CodingKeys: String, CodingKey {
        case content, nextContentUrl, replaceRegex
    }
}

// MARK: - Converter to our BookSource model

extension LegadoSource {
    func toBookSource() -> BookSource {
        return BookSource(
            name: bookSourceName,
            baseUrl: bookSourceUrl,
            searchUrl: extractSearchUrl(),
            detailUrl: "",
            chapterListUrl: "",
            contentUrl: ""
        )
    }

    private func extractSearchUrl() -> String {
        if let url = searchUrl, !url.isEmpty { return url }
        if let url = ruleSearch?.url, !url.isEmpty { return url }
        return "/search?keyword={keyword}"
    }

    func getSearchListSelector() -> String? {
        ruleSearch?.list
    }

    func getBookNameSelector() -> String? {
        ruleSearch?.name ?? ruleBookInfo?.name
    }

    func getAuthorSelector() -> String? {
        ruleSearch?.author ?? ruleBookInfo?.author
    }

    func getContentSelector() -> String? {
        ruleContent?.content
    }

    func getTocListSelector() -> String? {
        ruleToc?.list
    }

    func getTocNameSelector() -> String? {
        ruleToc?.name
    }
}

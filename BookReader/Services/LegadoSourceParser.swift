import Foundation
import SwiftSoup

final class LegadoSourceParser {
    let source: BookSource
    private var legadoRule: LegadoSource?

    init(source: BookSource, legadoRule: LegadoSource? = nil) {
        self.source = source
        self.legadoRule = legadoRule
    }

    func searchBooks(keyword: String) async throws -> [Book] {
        let url = buildSearchUrl(keyword: keyword)
        let html = try await NetworkService.shared.fetch(urlString: url)
        return parseSearchResult(html: html)
    }

    func getBookDetail(bookUrl: String) async throws -> Book {
        let url = bookUrl.hasPrefix("http") ? bookUrl : "\(source.baseUrl)\(bookUrl)"
        let html = try await NetworkService.shared.fetch(urlString: url)
        return parseDetail(html: html, bookUrl: bookUrl)
    }

    func getChapterList(bookUrl: String) async throws -> [Chapter] {
        let url = bookUrl.hasPrefix("http") ? bookUrl : "\(source.baseUrl)\(bookUrl)"
        let html = try await NetworkService.shared.fetch(urlString: url)
        return parseChapterList(html: html, bookUrl: bookUrl)
    }

    func getChapterContent(chapterUrl: String) async throws -> String {
        let url = chapterUrl.hasPrefix("http") ? chapterUrl : "\(source.baseUrl)\(chapterUrl)"
        let html = try await NetworkService.shared.fetch(urlString: url)
        return parseContent(html: html)
    }

    // MARK: - URL Building

    private func buildSearchUrl(keyword: String) -> String {
        var url = source.searchUrl
            .replacingOccurrences(of: "{keyword}", with: keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword)
            .replacingOccurrences(of: "{{key}}", with: keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword)

        if !url.hasPrefix("http") { url = "\(source.baseUrl)\(url)" }
        return url
    }

    // MARK: - Search with CSS Selectors

    private func parseSearchResult(html: String) -> [Book] {
        do {
            let doc = try SwiftSoup.parse(html)
            var books: [Book] = []

            if let rule = legadoRule?.ruleSearch,
               let listSelector = rule.list {

                let elements = try doc.select(listSelector)

                for element in try elements.array() {
                    let name = extractValue(from: element, rule: rule.name) ?? ""
                    let author = extractValue(from: element, rule: rule.author) ?? ""
                    let cover = extractAttribute(from: element, rule: rule.cover, attr: "src") ?? ""
                    let href: String
                    if let extractedHref = extractAttribute(from: element, rule: rule.tocUrl, attr: "href") {
                        href = extractedHref
                    } else if let absHref = try? element.absUrl("href"), !absHref.isEmpty {
                        href = absHref
                    } else {
                        href = ""
                    }

                    if !name.isEmpty {
                        books.append(Book(
                            bookUrl: href,
                            title: name,
                            author: author
                        ))
                    }
                }
            } else {
                books = fallbackSearchParse(html: html)
            }

            return Array(books.prefix(30))
        } catch {
            print("Legado search error: \(error)")
            return []
        }
    }

    // MARK: - Detail with CSS Selectors

    private func parseDetail(html: String, bookUrl: String) -> Book {
        do {
            let doc = try SwiftSoup.parse(html)
            let rule = legadoRule?.ruleBookInfo

            let title = extractValue(doc: doc, selector: rule?.name) ?? "未知书名"
            let author = extractValue(doc: doc, selector: rule?.author) ?? ""
            let cover = extractAttribute(doc: doc, selector: rule?.cover, attr: "src") ?? ""
            let intro = extractValue(doc: doc, selector: rule?.intro) ?? ""
            let kind = extractValue(doc: doc, selector: rule?.kind) ?? ""
            let lastChapter = extractValue(doc: doc, selector: rule?.lastChapter) ?? ""

            return Book(
                bookUrl: bookUrl,
                title: title,
                author: author
            )
        } catch {
            return Book(bookUrl: bookUrl, title: "加载失败")
        }
    }

    // MARK: - Chapter List with CSS Selectors

    private func parseChapterList(html: String, bookUrl: String) -> [Chapter] {
        do {
            let doc = try SwiftSoup.parse(html)
            var chapters: [Chapter] = []

            if let rule = legadoRule?.ruleToc,
               let listSelector = rule.list {
                let elements = try doc.select(listSelector)

                for (index, element) in try elements.array().enumerated() {
                    let title = extractValue(from: element, rule: rule.name) ?? ""
                    let href: String
                    if let extractedHref = extractAttribute(from: element, rule: rule.tocUrl, attr: "href") {
                        href = extractedHref
                    } else if let absHref = try? element.absUrl("href"), !absHref.isEmpty {
                        href = absHref
                    } else {
                        href = ""
                    }

                    if !title.isEmpty {
                        chapters.append(Chapter(
                            bookUrl: bookUrl,
                            title: title,
                            url: href,
                            order: index
                        ))
                    }
                }
            } else {
                chapters = fallbackChapterParse(html: html, bookUrl: bookUrl)
            }

            return chapters
        } catch {
            print("Legado chapter parse error: \(error)")
            return []
        }
    }

    // MARK: - Content with CSS Selectors

    private func parseContent(html: String) -> String {
        do {
            let doc = try SwiftSoup.parse(html)

            if let contentSelector = legadoRule?.ruleContent?.content {
                let parts = contentSelector.components(separatedBy: "@")
                let selector = parts[0]
                let attr = parts.count > 1 ? parts[1] : "text"

                if let el = try? doc.select(selector).first() {
                    var text: String
                    switch attr.lowercased() {
                    case "html", "innerhtml":
                        text = try el.html()
                    case "text", "owntext", "":
                        text = try el.text()
                    default:
                        text = try el.attr(attr)
                    }

                    text = applyReplaceRules(text: text)
                    return cleanText(text)
                }
            }

            return fallbackContentParse(html: html)
        } catch {
            return ""
        }
    }

    // MARK: - Core Selector Engine

    private func extractValue(from element: Element, rule: String?) -> String? {
        guard let rule, !rule.isEmpty else { return nil }

        let parts = rule.components(separatedBy: "@")
        let selector = parts[0]
        let attr = parts.count > 1 ? parts[1].lowercased() : "text"

        do {
            if let el = try? element.select(selector).first() {
                switch attr {
                case "text": return try el.text().trimmingCharacters(in: .whitespacesAndNewlines)
                case "html", "innerhtml": return try el.html()
                case "owntext": return try el.ownText()
                default:
                    let val = try el.attr(attr)
                    return val.isEmpty ? nil : val
                }
            }
        } catch { return nil }
        return nil
    }

    private func extractValue(doc: Document, selector: String?) -> String? {
        guard let selector, !selector.isEmpty else { return nil }
        let parts = selector.components(separatedBy: "@")
        let sel = parts[0]
        let attr = parts.count > 1 ? parts[1].lowercased() : "text"
        do {
            if let el = try? doc.select(sel).first() {
                switch attr {
                case "text": return try el.text().trimmingCharacters(in: .whitespacesAndNewlines)
                case "html": return try el.html()
                default: return try el.attr(attr)
                }
            }
        } catch { return nil }
        return nil
    }

    private func extractAttribute(from element: Element, rule: String?, attr: String) -> String? {
        guard let rule, !rule.isEmpty else { return nil }
        do {
            if let el = try? element.select(rule).first() {
                let value = try el.attr(attr)
                return value.isEmpty ? (try? el.absUrl(attr)) ?? nil : value
            }
        } catch { return nil }
        return nil
    }

    private func extractAttribute(doc: Document, selector: String?, attr: String) -> String? {
        guard let selector, !selector.isEmpty else { return nil }
        do {
            if let el = try? doc.select(selector).first() {
                let value = try el.attr(attr)
                return value.isEmpty ? (try? el.absUrl(attr)) ?? nil : value
            }
        } catch { return nil }
        return nil
    }

    // MARK: - Replace Rules

    private func applyReplaceRules(text: String) -> String {
        var result = text
        if let replaceRegex = legadoRule?.ruleContent?.replaceRegex {
            for pattern in replaceRegex where pattern.count >= 2 {
                let regex = pattern[0]
                let replacement = pattern.count > 1 ? pattern[1] : ""
                result = result.replacingOccurrences(of: regex, with: replacement, options: .regularExpression)
            }
        }
        return result
    }

    // MARK: - Fallback Parsers (original simple logic)

    private func fallbackSearchParse(html: String) -> [Book] {
        SourceParser(source: source).parseSearchResult(html: html)
    }

    private func fallbackChapterParse(html: String, bookUrl: String) -> [Chapter] {
        SourceParser(source: source).parseChapterList(html: html, bookUrl: bookUrl)
    }

    private func fallbackContentParse(html: String) -> String {
        SourceParser(source: source).parseContent(html: html)
    }

    private func cleanText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\s{2,}+", with: "\n\n", options: .regularExpression)
            .replacingOccurrences(of: "本章未完.*", with: "", options: .regularExpression)
            .replacingOccurrences(of: "请记住本站域名.*", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

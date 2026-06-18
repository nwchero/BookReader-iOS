import Foundation
import SwiftSoup

final class SourceParser {
    let source: BookSource

    init(source: BookSource) {
        self.source = source
    }

    func searchBooks(keyword: String) async throws -> [Book] {
        let url = buildSearchUrl(keyword: keyword)
        let html = try await NetworkService.shared.fetch(urlString: url, method: source.searchMethod)
        return parseSearchResult(html: html)
    }

    func getBookDetail(bookUrl: String) async throws -> Book {
        let url = bookUrl.hasPrefix("http") ? bookUrl : "\(source.baseUrl)\(bookUrl)"
        let html = try await NetworkService.shared.fetch(urlString: url)
        return parseDetail(html: html, bookUrl: bookUrl)
    }

    func getChapterList(bookUrl: String) async throws -> [Chapter] {
        let url = buildChapterListUrl(bookUrl: bookUrl)
        let html = try await NetworkService.shared.fetch(urlString: url)
        return parseChapterList(html: html, bookUrl: bookUrl)
    }

    func getChapterContent(chapterUrl: String) async throws -> String {
        let url = chapterUrl.hasPrefix("http") ? chapterUrl : "\(source.baseUrl)\(chapterUrl)"
        let html = try await NetworkService.shared.fetch(urlString: url)
        return parseContent(html: html)
    }

    private func buildSearchUrl(keyword: String) -> String {
        var url = source.searchUrl.replacingOccurrences(of: "{keyword}", with: keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword)
        if !url.hasPrefix("http") { url = "\(source.baseUrl)\(url)" }
        return url
    }

    private func buildChapterListUrl(bookUrl: String) -> String {
        var url = source.chapterListUrl.replacingOccurrences(of: "{bookUrl}", with: bookUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? bookUrl)
        if !url.hasPrefix("http") { url = "\(source.baseUrl)\(url)" }
        return url
    }

    // MARK: - Search Result Parsing

    func parseSearchResult(html: String) -> [Book] {
        var books: [Book] = []
        do {
            let doc = try SwiftSoup.parse(html)

            let selectors = [
                ".result-list .book-item",
                ".search-result .book-info",
                ".novellist li",
                ".result-item"
            ]

            var foundElements: Elements?
            for selector in selectors {
                if let elements = try? doc.select(selector), !elements.isEmpty() {
                    foundElements = elements
                    break
                }
            }

            if let elements = foundElements {
                for element in elements.array() {
                    guard let titleEl = (try? element.select(".book-title, .name, h3 a, h4 a, .s1 a").first())
                              ?? (try? element.select("a[href]").first()),
                          let href = try? titleEl.absUrl("href"),
                          let title = try? titleEl.text().trimmingCharacters(in: .whitespacesAndNewlines),
                          !title.isEmpty else { continue }

                    let authorEl = try? element.select(".author, .s2, .writer").first()
                    let author = try? authorEl?.text().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                    books.append(Book(
                        bookUrl: href,
                        title: title,
                        author: author ?? ""
                    ))
                }
            } else {
                let links = try doc.select("a[href*='/book/'], a[href*='/novel/'], a[href*='.html']")
                for link in links.array() {
                    guard let href = try? link.absUrl("href"),
                          let text = try? link.text().trimmingCharacters(in: .whitespacesAndNewlines),
                          !text.isEmpty, text.count >= 2 else { continue }

                    books.append(Book(
                        bookUrl: href,
                        title: text,
                        author: ""
                    ))
                }
            }
        } catch {
            print("Parse search error: \(error)")
        }
        return Array(books.prefix(30))
    }

    // MARK: - Detail Parsing

    func parseDetail(html: String, bookUrl: String) -> Book {
        do {
            let doc = try SwiftSoup.parse(html)

            let titleSelectors = ["#info h1", ".book-info h1", ".detail h1", ".book-title"]
            var title = ""
            for selector in titleSelectors {
                if let el = try? doc.select(selector).first(),
                   let t = try? el.text().trimmingCharacters(in: .whitespacesAndNewlines),
                   !t.isEmpty {
                    title = t
                    break
                }
            }
            if title.isEmpty {
                title = try doc.title().replacingOccurrences(of: "_.*$", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
            }

            let authorEl = try? doc.select(".book-info .author, #info p:contains(作者), .writer, .author").first()
            let authorRaw = try? authorEl?.text() ?? ""
            let author = authorRaw?.replacingOccurrences(of: "作者[：:]?", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            let coverEl = try? doc.select(".book-cover img, #fmimg img, .cover img").first()
            let coverUrl = try? coverEl?.absUrl("src") ?? ""

            let descEl = try? doc.select("#intro, .book-intro, .description, .book-desc, .intro").first()
            let descriptionText = try? descEl?.text().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            let category = try? doc.select(".category, .type, .sort").first()?.text().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let status = try? doc.select(".status, .book-state").first()?.text().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            let latestEls = try? doc.select("#info p:last-child, .latest-chapter, .newest").array()
            var latestChapter = ""
            if let last = latestEls?.last {
                latestChapter = (try? last.text().replacingOccurrences(of: "最新章节[：:]?", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
            }

            return Book(
                bookUrl: bookUrl,
                title: title.isEmpty ? "未知书名" : title,
                author: author
            )
        } catch {
            return Book(bookUrl: bookUrl, title: "加载失败")
        }
    }

    // MARK: - Chapter List Parsing

    func parseChapterList(html: String, bookUrl: String) -> [Chapter] {
        var chapters: [Chapter] = []
        do {
            let doc = try SwiftSoup.parse(html)

            let listSelectors = ["#list dl dd a", ".chapter-list a", ".volume-list a", "#contentlist a"]
            var items: Elements?

            for selector in listSelectors {
                if let els = try? doc.select(selector), !els.isEmpty() {
                    items = els
                    break
                }
            }

            if let elements = items {
                for (index, item) in elements.array().enumerated() {
                    guard let title = try? item.text().trimmingCharacters(in: .whitespacesAndNewlines),
                          let url = try? item.absUrl("href"),
                          !title.isEmpty else { continue }

                    chapters.append(Chapter(
                        bookUrl: bookUrl,
                        title: title,
                        url: url,
                        order: index
                    ))
                }
            } else {
                let links = try doc.select("a[href]")
                for (index, link) in links.array().enumerated() {
                    guard let href = try? link.absUrl("href"),
                          let text = try? link.text().trimmingCharacters(in: .whitespacesAndNewlines),
                          text.count >= 2 && text.count <= 50,
                          text.range(of: "首页|书架|目录", options: .regularExpression) == nil else { continue }

                    chapters.append(Chapter(
                        bookUrl: bookUrl,
                        title: text,
                        url: href,
                        order: index
                    ))
                }
            }
        } catch {
            print("Parse chapter error: \(error)")
        }
        return chapters
    }

    // MARK: - Content Parsing

    func parseContent(html: String) -> String {
        do {
            let doc = try SwiftSoup.parse(html)

            let contentSelectors = [
                "#content", "#BookText", "#booktext", "#nr_title + *",
                ".book-content", ".chapter-content", ".read-content",
                "#contentw", "#txt", ".text", ".content-text",
                ".chapter_content", "#chaptercontent", "article"
            ]

            for selector in contentSelectors {
                if let el = try? doc.select(selector).first(),
                   let text = try? el.text(), text.count > 50 {
                    let innerHtml = (try? el.html()) ?? ""
                    return cleanContent(html: innerHtml)
                }
            }

            if let body = try? doc.body() {
                try? body.select("script, style, nav, header, footer, aside, .ad, .advertisement, .comment").remove()

                let rawText = (try? body.text()) ?? ""
                let paragraphs = rawText.components(separatedBy: "\n")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { $0.count > 5 }
                    .prefix(100)

                return paragraphs.joined(separator: "\n\n")
            }
            return ""
        } catch {
            return ""
        }
    }

    private func cleanContent(html: String) -> String {
        do {
            let text = try SwiftSoup.parse(html).text()
            return text
                .replacingOccurrences(of: "\\s{2,}+", with: "\n\n", options: .regularExpression)
                .replacingOccurrences(of: "本章未完，请点击下一页继续阅读.*", with: "", options: .regularExpression)
                .replacingOccurrences(of: "请记住本站域名.*", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return ""
        }
    }
}

import Foundation

@Observable
final class SourceImportService {
    var isImporting: Bool = false
    var importProgress: Double = 0
    var importedCount: Int = 0
    var totalSources: Int = 0
    var errorMessage: String?
    var lastImportedSources: [BookSource] = []

    private let dataManager = DataManager.shared

    func importFromURL(_ urlString: String) async {
        await importFromURL(urlString, isLocalFile: false)
    }

    func importFromLocalFile(_ fileURL: URL) async {
        await importFromURL(fileURL.absoluteString, isLocalFile: true)
    }

    private func importFromURL(_ urlString: String, isLocalFile: Bool) async {
        isImporting = true
        importProgress = 0
        importedCount = 0
        errorMessage = nil
        lastImportedSources = []

        do {
            let data: Data
            if isLocalFile {
                data = try Data(contentsOf: URL(fileURLWithPath: urlString))
            } else {
                guard let url = URL(string: urlString) else {
                    throw ImportError.invalidURL
                }
                let (responseData, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw ImportError.serverError
                }
                data = responseData
            }

            importProgress = 0.2

            let sources = try parseLegadoJSON(data)
            totalSources = sources.count
            importProgress = 0.4

            guard !sources.isEmpty else {
                throw ImportError.noSourcesFound
            }

            for (index, legadoSource) in sources.enumerated() {
                let bookSource = legadoSource.toBookSource()

                if dataManager.getSourceById(id: bookSource.id) == nil {
                    dataManager.saveSource(bookSource)
                    lastImportedSources.append(bookSource)
                    importedCount += 1
                }

                importProgress = 0.4 + (Double(index + 1) / Double(sources.count)) * 0.6
            }

            isImporting = false

        } catch {
            self.errorMessage = error.localizedDescription
            isImporting = false
        }
    }

    func importDefaultSources() async {
        // Try to load from bundled default sources file
        guard let bundlePath = Bundle.main.path(forResource: "default_sources", ofType: "json") else {
            await importFromURL("https://bitbucket.org/xiu2/yuedu/raw/master/shuyuan")
            return
        }
        await importFromLocalFile(URL(fileURLWithPath: bundlePath))
    }

    private func parseLegadoJSON(_ data: Data) throws -> [LegadoSource] {
        let json = try JSONSerialization.jsonObject(with: data)

        if let jsonArray = json as? [[String: Any]] {
            let decoder = JSONDecoder()
            let jsonData = try JSONSerialization.data(withJSONObject: jsonArray)
            return try decoder.decode([LegadoSource].self, from: jsonData)
        } else if let jsonDict = json as? [String: Any] {
            let decoder = JSONDecoder()
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDict)
            return try decoder.decode(LegadoSource.self, from: jsonData).map { [$0] }.get() ?? []
        } else {
            throw ImportError.parseError
        }
    }

    enum ImportError: LocalizedError {
        case invalidURL
        case serverError
        case noSourcesFound
        case parseError

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "无效的URL地址"
            case .serverError: return "服务器无响应"
            case .noSourcesFound: return "文件中没有找到有效的书源"
            case .parseError: return "书源文件格式解析失败"
            }
        }
    }
}

import Foundation
import SwiftUI

@Observable
final class SourceViewModel {
    var sources: [BookSource] = []
    var isLoading: Bool = false
    var showAddSheet: Bool = false
    var showEditSheet: Bool = false
    var editingSource: BookSource?
    var message: String?

    private let dataManager = DataManager.shared

    init() {
        loadSources()
    }

    func loadSources() {
        isLoading = true
        sources = dataManager.getAllSourcesIncludingDisabled()
        isLoading = false
    }

    func saveSource(_ source: BookSource) {
        dataManager.saveSource(source)
        message = source.id == UUID() ? "书源已添加" : "书源已更新"
        loadSources()
        showAddSheet = false
        showEditSheet = false
    }

    func deleteSource(_ source: BookSource) {
        dataManager.deleteSource(source)
        message = "书源已删除"
        loadSources()
    }

    func toggleEnabled(_ source: BookSource) {
        source.isEnabled.toggle()
        dataManager.saveSource(source)
        loadSources()
    }
}

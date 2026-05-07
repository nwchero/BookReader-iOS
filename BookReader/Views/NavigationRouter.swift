import SwiftUI

enum AppRoute: Hashable {
    case bookDetail(bookUrl: String)
    case reader(bookUrl: String, chapterIndex: Int)
}

struct NavigationRouter: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            TabBarView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .bookDetail(let bookUrl):
                        BookDetailView(bookUrl: bookUrl, path: $path)
                    case .reader(let bookUrl, let chapterIndex):
                        ReaderView(bookUrl: bookUrl, initialChapterIndex: chapterIndex, path: $path)
                    }
                }
        }
    }
}

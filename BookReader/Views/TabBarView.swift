import SwiftUI

struct TabBarView: View {
    @State private var selectedTab: Tab = .bookshelf

    enum Tab: String, CaseIterable {
        case bookshelf, discover, sources, settings
        var title: String {
            switch self {
            case .bookshelf: return "书架"
            case .discover: return "发现"
            case .sources: return "书源"
            case .settings: return "设置"
            }
        }
        var iconName: String {
            switch self {
            case .bookshelf: return "books.vertical"
            case .discover: return "magnifyingglass"
            case .sources: return "text.book.closed"
            case .settings: return "gearshape"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            BookshelfView()
                .tabItem {
                    Label(Tab.bookshelf.title, systemImage: Tab.bookshelf.iconName)
                }
                .tag(Tab.bookshelf)

            DiscoverView()
                .tabItem {
                    Label(Tab.discover.title, systemImage: Tab.discover.iconName)
                }
                .tag(Tab.discover)

            SourcesView()
                .tabItem {
                    Label(Tab.sources.title, systemImage: Tab.sources.iconName)
                }
                .tag(Tab.sources)

            SettingsView()
                .tabItem {
                    Label(Tab.settings.title, systemImage: Tab.settings.iconName)
                }
                .tag(Tab.settings)
        }
        .tint(AppTheme.primary)
    }
}

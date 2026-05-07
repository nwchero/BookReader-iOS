import SwiftUI
import SwiftData

@main
struct BookReaderApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BookSource.self,
            Book.self,
            Chapter.self,
            ReadingProgress.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {}

    var body: some Scene {
        WindowGroup {
            NavigationRouter()
                .onAppear {
                    DataManager.shared.configure(modelContext: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

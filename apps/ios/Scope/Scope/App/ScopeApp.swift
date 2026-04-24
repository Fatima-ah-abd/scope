import SwiftUI

@main
struct ScopeApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .environment(appModel)
            .tint(ScopeTheme.accent)
        }
    }
}

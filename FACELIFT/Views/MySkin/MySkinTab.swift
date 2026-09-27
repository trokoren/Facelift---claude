import SwiftUI

struct MySkinTab: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store
        NavigationStack(path: $store.mySkinPath) {
            MySkinView()
                .swipeBackEnabled()
                .navigationDestination(for: MySkinRoute.self) { route in
                    switch route {
                    case let .scan(id, isFresh):
                        AnalysisView(scanID: id, isFresh: isFresh)
                    }
                }
        }
    }
}

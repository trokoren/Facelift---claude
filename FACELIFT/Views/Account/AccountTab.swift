import SwiftUI

struct AccountTab: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store
        NavigationStack(path: $store.accountPath) {
            AccountView()
                .swipeBackEnabled()
                .navigationDestination(for: AccountRoute.self) { route in
                    switch route {
                    case .help:
                        HelpFeedbackView()
                    case .privacy:
                        PrivacyDataView()
                    case .policy:
                        PrivacyPolicyView()
                    }
                }
        }
    }
}

import SwiftUI

struct FLTabBar: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                let isActive = store.selectedTab == tab
                Button {
                    select(tab)
                } label: {
                    VStack(spacing: 5) {
                        TabIcon(tab: tab)
                            .font(.system(size: 21, weight: .ultraLight))
                            .frame(height: 26)
                        Text(tab.title)
                            .font(FLFont.sans(10))
                    }
                    .foregroundStyle(isActive ? Palette.rose : Palette.tabIdle)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 9)
                    .padding(.bottom, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle(scale: 0.92))
                .accessibilityAddTraits(isActive ? .isSelected : [])
            }
        }
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Palette.divider)
                .frame(height: 1)
        }
        .sensoryFeedback(.selection, trigger: store.selectedTab)
    }

    private func select(_ tab: AppTab) {
        if store.selectedTab == tab {
            switch tab {
            case .mySkin: store.mySkinPath = []
            case .account: store.accountPath = []
            default: break
            }
            return
        }
        store.selectedTab = tab
    }
}

private struct TabIcon: View {
    let tab: AppTab

    var body: some View {
        switch tab {
        case .scan:
            Image(systemName: "camera")
        case .mySkin:
            Image(systemName: "face.smiling")
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "asterisk")
                        .font(.system(size: 9, weight: .regular))
                        .offset(x: 9, y: -6)
                }
        case .progress:
            Image(systemName: "chart.line.uptrend.xyaxis")
        case .account:
            Image(systemName: "person")
        }
    }
}

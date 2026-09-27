import SwiftUI

/// A 47pt row used in the Account and Help cards.
struct SettingsRow<Accessory: View>: View {
    let title: String
    var value: String?
    var showsChevron: Bool = true
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(FLFont.sans(12.9))
                .foregroundStyle(Palette.ink)
            Spacer(minLength: 8)
            if let value {
                Text(value)
                    .font(FLFont.sans(12))
                    .foregroundStyle(Palette.quiet)
                    .lineLimit(1)
            }
            accessory()
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Palette.quiet)
            }
        }
        .frame(height: 47)
        .contentShape(Rectangle())
    }
}

extension SettingsRow where Accessory == EmptyView {
    init(title: String, value: String? = nil, showsChevron: Bool = true) {
        self.title = title
        self.value = value
        self.showsChevron = showsChevron
        self.accessory = { EmptyView() }
    }
}

struct RowDivider: View {
    var body: some View {
        Rectangle().fill(Palette.rowDivider).frame(height: 1)
    }
}

import SwiftUI

struct PrivacyDataView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var isConfirmingDelete: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BrandHeader(subtitle: "Privacy & Data.", onBack: { dismiss() })

                SectionLabel("YOUR DATA")
                    .padding(.horizontal, 28)
                    .padding(.top, 22)

                VStack(alignment: .leading, spacing: 14) {
                    point("Your camera feed is analysed in the moment and never saved as a photo.")
                    point("We keep your scores and recommendations so you can see your progress.")
                    point("Nothing is shared or sold. Your skin is your business.")
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardSurface()
                .padding(.horizontal, 24)
                .padding(.top, 12)

                SectionLabel("MANAGE")
                    .padding(.horizontal, 28)
                    .padding(.top, 22)

                VStack(spacing: 0) {
                    SettingsRow(title: "Scans saved", value: "\(store.scans.count)", showsChevron: false)
                    RowDivider()
                    Button {
                        isConfirmingDelete = true
                    } label: {
                        SettingsRow(title: "Delete scan history")
                    }
                    .buttonStyle(CardPressStyle())
                    .disabled(store.scans.count <= 1)
                    .opacity(store.scans.count <= 1 ? 0.5 : 1)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
                .cardSurface()
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .background(Palette.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("Delete older scans? Your latest scan is kept.", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete history", role: .destructive) {
                withAnimation { store.deleteHistory() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func point(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Circle()
                .fill(Palette.rose)
                .frame(width: 5, height: 5)
                .offset(y: -2)
            Text(text)
                .font(FLFont.sans(12.9))
                .foregroundStyle(Palette.body)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

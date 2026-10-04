import SwiftUI

/// Full-bleed editorial landing: "Your skin, finally understood."
struct ScanHomeView: View {
    @Environment(AppStore.self) private var store
    @State private var hasAppeared: Bool = false
    @State private var showsAlreadyScanned = false
    @State private var showsUsedUp = false

    var body: some View {
        ZStack {
            // The reader ignores the safe area first, so the photo is sized to the whole
            // screen (behind the status bar and home indicator) before being cropped.
            GeometryReader { geo in
                Image("woman_portrait_clean")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaleEffect(hasAppeared ? 1.0 : 1.06)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .background(Color(hex: 0x2A1A14))
            .ignoresSafeArea()
            .allowsHitTesting(false)

            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.18), location: 0),
                    .init(color: .clear, location: 0.22),
                    .init(color: .clear, location: 0.5),
                    .init(color: Color(hex: 0x1E100B).opacity(0.55), location: 0.78),
                    .init(color: Color(hex: 0x1E100B).opacity(0.8), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                Text("FACELIFT")
                    .font(FLFont.serif(14))
                    .tracking(5.6)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 10)

                Spacer()

                VStack(spacing: -4) {
                    Text("Your skin,")
                        .font(FLFont.serif(43))
                    Text("finally understood.")
                        .font(FLFont.serifItalic(44))
                }
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 14)

                Button {
                    switch ScanAllowance.current {
                    case .open: store.startScan()
                    case .alreadyScanned: showsAlreadyScanned = true
                    case .usedUp: showsUsedUp = true
                    }
                } label: {
                    Text("Scan my face")
                        .font(FLFont.sans(15.2))
                        .tracking(0.5)
                        .foregroundStyle(.white)
                        .frame(width: 260, height: 51)
                        .background(Palette.rose, in: Capsule())
                }
                .buttonStyle(PressableStyle())
                .padding(.top, 36)
                .opacity(hasAppeared ? 1 : 0)

                Button {
                    store.goHome()
                } label: {
                    Text("take me home")
                        .font(FLFont.sans(13.5))
                        .foregroundStyle(.white.opacity(0.62))
                        .frame(height: 44)
                        .padding(.horizontal, 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
                .padding(.top, 16)
                .padding(.bottom, 54)
                .opacity(hasAppeared ? 1 : 0)
            }
            .padding(.horizontal, 24)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: store.isScanning)
        .alert("You've already scanned today", isPresented: $showsAlreadyScanned) {
            Button("Not now", role: .cancel) {}
            Button("Scan anyway") { store.startScan() }
        } message: {
            Text("Skin changes slowly, so another scan today won't show much new. For the clearest progress, scan every few days in the same spot and light.")
        }
        .alert("Your next scan unlocks tomorrow", isPresented: $showsUsedUp) {
            Button("Got it", role: .cancel) {}
        } message: {
            Text("Skin changes slowly, and a little time between scans makes your progress easier to see.")
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.4)) {
                hasAppeared = true
            }
        }
    }
}

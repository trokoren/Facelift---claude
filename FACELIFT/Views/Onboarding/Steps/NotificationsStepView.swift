import SwiftUI
import UserNotifications

/// "Don't forget about your skin." — lock-screen mock and the permission ask.
struct NotificationsStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @State private var isRequesting: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                OnboardingBackButton { flow.back() }
                    .padding(.leading, 10)
                Spacer()
            }
            .frame(height: 44)

            OnboardingTitle(
                title: "Don't forget\nabout your skin.",
                subtitle: "We'll remind you to scan and track your progress.\nWe won't spam, pinky promise.",
                titleSize: 34
            )
            .padding(.horizontal, 24)
            .padding(.top, 4)

            phoneMock
                .padding(.top, 24)
                .padding(.horizontal, 48)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.canvas.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            VStack(spacing: 10) {
                OnboardingCTA(title: "Turn On Notifications", isEnabled: !isRequesting) {
                    Task { await request() }
                }
                Button {
                    flow.next()
                } label: {
                    Text("Not now")
                        .font(FLFont.sans(16))
                        .foregroundStyle(Palette.stone)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .background(
                LinearGradient(colors: [Palette.canvas.opacity(0), Palette.canvas, Palette.canvas], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
        }
    }

    private var phoneMock: some View {
        VStack(spacing: 0) {
            HStack {
                Text("9:41")
                    .font(FLFont.sans(15, .semibold))
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "cellularbars")
                    Image(systemName: "wifi")
                    Image(systemName: "battery.100percent")
                }
                .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 26)
            .padding(.top, 22)

            Capsule()
                .fill(Color(hex: 0x1C1614))
                .frame(width: 112, height: 32)
                .padding(.top, 6)

            Text("9:41")
                .font(FLFont.sans(64, .light))
                .foregroundStyle(Palette.ink)
                .padding(.top, 26)
            Text("Tuesday, September 9")
                .font(FLFont.sans(15))
                .foregroundStyle(Palette.body)
                .padding(.top, -6)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Text("F")
                        .font(FLFont.serif(15))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            LinearGradient(colors: [Color(hex: 0xE39A94), Palette.rose], startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                        )
                    Text("FACELIFT")
                        .font(FLFont.sans(14, .medium))
                        .foregroundStyle(Palette.stone)
                    Spacer()
                    Text("now")
                        .font(FLFont.sans(13))
                        .foregroundStyle(Palette.mist)
                }
                Text("Time for your weekly scan ✦")
                    .font(FLFont.sans(15.5, .semibold))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 4)
                Text("See how your skin has changed since last week. Your score is waiting.")
                    .font(FLFont.sans(14.5))
                    .foregroundStyle(Palette.body)
                    .lineSpacing(3)
            }
            .padding(14)
            .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 30)

            Spacer(minLength: 60)
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [Color(hex: 0xF8E7E3), Color(hex: 0xF9F1EC), Color(hex: 0xF6EDE8)], startPoint: .top, endPoint: .bottom)
        )
        .clipShape(.rect(cornerRadius: 46, style: .continuous))
        .padding(8)
        .background(Color(hex: 0xE6E0DB), in: RoundedRectangle(cornerRadius: 54, style: .continuous))
        .frame(maxHeight: 420, alignment: .top)
        .clipped()
    }

    private func request() async {
        isRequesting = true
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        flow.answers.notificationsRequested = granted
        isRequesting = false
        flow.next()
    }
}

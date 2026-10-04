import SwiftUI
import UserNotifications

/// The commitment moment before the scan: her 28-day glow-up only happens if she keeps
/// showing up, and the reminders are how. Lock-screen mock shows the payoff, then the ask.
struct NotificationsStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @Environment(\.openURL) private var openURL
    @State private var isRequesting: Bool = false
    @State private var isDenied: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                OnboardingBackButton { flow.back() }
                    .padding(.leading, 10)
                Spacer()
            }
            .frame(height: 44)

            OnboardingTitle(
                title: "Your best skin is\n28 days away.",
                subtitle: "Don't forget about your skin!\nOne gentle nudge a week keeps you on track.",
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
                OnboardingCTA(title: isDenied ? "Open Settings" : "Remind me to Scan", isEnabled: !isRequesting) {
                    Task { await request() }
                }
                Button {
                    flow.next()
                } label: {
                    Text(isDenied ? "Continue without reminders" : "Not now")
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

            VStack(spacing: 10) {
                NotificationBubble(
                    time: "now",
                    title: "Week 4: you did it ✦",
                    message: "Your skin score is up 12 points since day one. Come see the difference."
                )
                NotificationBubble(
                    time: "1w ago",
                    title: "Time for your weekly scan",
                    message: "Two minutes. Let's see what changed."
                )
                .opacity(0.75)
                .scaleEffect(0.95)
            }
            .padding(.horizontal, 16)
            .padding(.top, 26)

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
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus

        switch status {
        case .notDetermined:
            // First time: Apple's "Allow notifications?" popup.
            isRequesting = true
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            flow.answers.notificationsRequested = granted
            isRequesting = false
            flow.next()
        case .denied:
            // She said no before; iOS won't ask twice, so offer Settings instead.
            if isDenied, let url = URL(string: UIApplication.openSettingsURLString) {
                openURL(url)
            } else {
                withAnimation(.easeOut(duration: 0.2)) { isDenied = true }
            }
        default:
            // Already allowed.
            flow.answers.notificationsRequested = true
            flow.next()
        }
    }
}

private struct NotificationBubble: View {
    let time: String
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
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
                Text(time)
                    .font(FLFont.sans(13))
                    .foregroundStyle(Palette.mist)
            }
            Text(title)
                .font(FLFont.sans(15.5, .semibold))
                .foregroundStyle(Palette.ink)
                .padding(.top, 4)
            Text(message)
                .font(FLFont.sans(14.5))
                .foregroundStyle(Palette.body)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Palette.ink.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

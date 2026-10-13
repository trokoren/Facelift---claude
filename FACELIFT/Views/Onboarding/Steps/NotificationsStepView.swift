import SwiftUI
import UserNotifications

/// The commitment moment before the scan: results take about 4 steady weeks, and a weekly
/// check-in is how she gets there. She picks the day and time, sees exactly what we'll send,
/// then Apple's permission popup appears. "Not now" always moves on.
struct NotificationsStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @Environment(\.openURL) private var openURL
    @State private var isRequesting: Bool = false
    @State private var isDenied: Bool = false
    @State private var weekday: Int = ReminderTime.weekday
    @State private var hour: Int = ReminderTime.hour

    private let benefits = ["Make real progress", "See what's working", "Catch changes early"]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                OnboardingBackButton { flow.back() }
                    .padding(.leading, 10)
                Spacer()
            }
            .frame(height: 44)

            ScrollView {
                VStack(spacing: 0) {
                    OnboardingTitle(title: "Your skin needs\n4 steady weeks.", subtitle: nil, titleSize: 34)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(benefits, id: \.self) { line in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Palette.rose)
                                Text(line)
                                    .font(FLFont.sans(16))
                                    .foregroundStyle(Palette.ink)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 40)
                    .padding(.top, 18)

                    picker
                        .padding(.top, 24)

                    lockScreen
                        .padding(.top, 22)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 150)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.canvas.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            VStack(spacing: 10) {
                OnboardingCTA(title: isDenied ? "Open Settings" : "Keep me on track", isEnabled: !isRequesting) {
                    Task { await request() }
                }
                Button {
                    Analytics.track(.notificationsSkipped)
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
        .sensoryFeedback(.selection, trigger: weekday)
        .sensoryFeedback(.selection, trigger: hour)
    }

    // MARK: - Day and time

    private var picker: some View {
        VStack(spacing: 12) {
            Text("When should we check in?")
                .font(FLFont.sans(14, .medium))
                .foregroundStyle(Palette.body)
            HStack(spacing: 8) {
                ForEach(ReminderTime.days, id: \.value) { day in
                    chip(day.label, isOn: weekday == day.value) { weekday = day.value }
                }
            }
            HStack(spacing: 8) {
                ForEach(ReminderTime.times, id: \.value) { time in
                    chip(time.label, isOn: hour == time.value) { hour = time.value }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func chip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(FLFont.sans(14, isOn ? .semibold : .regular))
                .foregroundStyle(isOn ? .white : Palette.ink)
                .padding(.horizontal, 16)
                .frame(height: 38)
                .background(isOn ? Palette.rose : Palette.chip, in: Capsule())
        }
        .buttonStyle(PressableStyle(scale: 0.94))
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    // MARK: - Preview

    /// What she'll actually get: the weekly check-in at the time she picked, and the trial heads-up.
    private var lockScreen: some View {
        VStack(spacing: 0) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(FLFont.sans(14))
                .foregroundStyle(Palette.body)
            VStack(spacing: 10) {
                NotificationBubble(
                    time: ReminderTime.label(weekday: weekday, hour: hour),
                    title: "Time for your weekly scan",
                    message: "Same light, same spot. Let's see how your skin is doing this week."
                )
                NotificationBubble(
                    time: "Day 2",
                    title: "Your free trial ends tomorrow",
                    message: "You can manage or cancel anytime in Settings."
                )
                .opacity(0.8)
                .scaleEffect(0.96)
            }
            .padding(.top, 14)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .background(
            LinearGradient(colors: [Color(hex: 0xF8E7E3), Color(hex: 0xF9F1EC), Color(hex: 0xF6EDE8)], startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 32, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Permission

    private func request() async {
        ReminderTime.save(weekday: weekday, hour: hour)
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus

        switch status {
        case .notDetermined:
            // First time: Apple's "Allow notifications?" popup.
            isRequesting = true
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            flow.answers.notificationsRequested = granted
            Analytics.track(.notificationsAnswered, [
                "allowed": granted,
                "reminder_day": ReminderTime.days.first { $0.value == weekday }?.label ?? "",
                "reminder_time": hour < 12 ? "morning" : "evening",
            ])
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

import SwiftUI
import UserNotifications

/// Scan reminders, kept simple: one promise, the reminder she'll get, and the days and
/// time (Sunday morning unless she changes it; any number of days). Then Apple's permission
/// popup. "Not now" always moves on.
struct NotificationsStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @Environment(\.openURL) private var openURL
    @State private var isRequesting: Bool = false
    @State private var isDenied: Bool = false
    @State private var weekdays: Set<Int> = Set(ReminderTime.weekdays)
    @State private var hour: Int = ReminderTime.hour

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
                    OnboardingTitle(title: "We will remind you\nto scan every week.", subtitle: nil, titleSize: 34)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)

                    preview
                        .padding(.top, 30)
                        .padding(.horizontal, 24)

                    picker
                        .padding(.top, 30)
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
                OnboardingCTA(title: isDenied ? "Open Settings" : "Turn on reminders", isEnabled: !isRequesting) {
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
        .sensoryFeedback(.selection, trigger: weekdays)
        .sensoryFeedback(.selection, trigger: hour)
    }

    // MARK: - Day and time

    private var picker: some View {
        VStack(spacing: 12) {
            Text("Pick your days and time")
                .font(FLFont.sans(14, .medium))
                .foregroundStyle(Palette.stone)
            HStack(spacing: 6) {
                ForEach(ReminderTime.days, id: \.value) { day in
                    dayChip(day.label, isOn: weekdays.contains(day.value)) { toggle(day.value) }
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

    /// Tap to add or remove a day. At least one day always stays on.
    private func toggle(_ day: Int) {
        if weekdays.contains(day) {
            if weekdays.count > 1 { weekdays.remove(day) }
        } else {
            weekdays.insert(day)
        }
    }

    private func dayChip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(FLFont.sans(13.5, isOn ? .semibold : .regular))
                .foregroundStyle(isOn ? .white : Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isOn ? Palette.rose : Palette.chip, in: Capsule())
        }
        .buttonStyle(PressableStyle(scale: 0.94))
        .accessibilityAddTraits(isOn ? .isSelected : [])
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

    /// The reminder exactly as she'll get it, on her next picked day at her time.
    private var preview: some View {
        NotificationBubble(
            time: ReminderTime.label(weekday: ReminderTime.nextDay(of: Array(weekdays)), hour: hour),
            title: ReminderTime.reminderTitle(dayCount: weekdays.count),
            message: "Same light, same spot. Let's see how your skin is doing this week."
        )
        .padding(14)
        .background(
            LinearGradient(colors: [Color(hex: 0xF8E7E3), Color(hex: 0xF6EDE8)], startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .animation(.easeOut(duration: 0.2), value: weekdays)
        .animation(.easeOut(duration: 0.2), value: hour)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Permission

    private func request() async {
        ReminderTime.save(weekdays: Array(weekdays), hour: hour)
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
                "reminder_day": weekdays.sorted().map(ReminderTime.dayLabel).joined(separator: ","),
                "reminder_day_count": weekdays.count,
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

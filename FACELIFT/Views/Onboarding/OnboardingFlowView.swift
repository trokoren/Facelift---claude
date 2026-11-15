import SwiftUI

/// Hosts the whole first-run journey and slides between steps.
struct OnboardingFlowView: View {
    @Environment(AppStore.self) private var store
    @State private var flow = OnboardingStore()

    var body: some View {
        ZStack(alignment: .top) {
            stepView
                .id(flow.step)
                .transition(transition)

            if flow.step.showsProgress {
                OnboardingProgressBar(progress: flow.progress)
                    .transition(.opacity)
            }
        }
        .environment(flow)
        .preferredColorScheme(flow.step.isDark ? .dark : .light)
        .sensoryFeedback(.selection, trigger: flow.step)
        // She paid on the website and opened her link: bring over her quiz answers and
        // skip the questions. Without them she answers here as usual (no paywall either way).
        .onChange(of: Subscriptions.shared.webRedemptions) { _, _ in
            guard flow.step.rawValue < OnboardingStep.location.rawValue else { return }
            Task {
                var answers = flow.answers
                if await WebQuizAnswers.load(into: &answers) {
                    flow.answers = answers
                    flow.jump(to: .location)
                }
            }
        }
        .onAppear {
            // Later steps are tracked as she moves; the first screen is tracked here.
            Analytics.track(.onboardingStarted)
            Analytics.track(.onboardingStepViewed, ["step": "\(flow.step)", "step_number": 1])
        }
    }

    private var transition: AnyTransition {
        let forward = flow.direction == .forward
        return .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    @ViewBuilder
    private var stepView: some View {
        switch flow.step {
        case .hero: HeroStepView()
        case .age: AgeStepView()
        case .skinType: SkinTypeStepView()
        case .science: ScienceStepView()
        case .painPoints: PainPointsStepView()
        case .sensitivity: SensitivityStepView()
        case .notAlone: NotAloneStepView()
        case .mainGoal: MainGoalStepView()
        case .results28: Results28StepView()
        case .budget: BudgetStepView()
        case .approach: ApproachStepView()
        case .healthContext: HealthContextStepView()
        case .reviewAsk: ReviewAskStepView()
        case .spfHabits: SPFStepView()
        case .currentRoutine: RoutineStepView()
        case .location: LocationStepView()
        case .notifications: NotificationsStepView()
        case .readyToScan: ReadyToScanStepView()
        case .scanInstructions: ScanInstructionsStepView()
        case .cameraPermission: CameraPermissionStepView()
        case .scanLoading: ScanLoadingStepView()
        case .paywallPreview: PaywallPreviewStepView()
        case .paywall: PaywallStepView()
        }
    }
}

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
        case .splash: SplashStepView()
        case .tracking: TrackingStepView()
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

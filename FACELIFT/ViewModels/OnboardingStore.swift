import SwiftUI
import Observation

/// Drives the first-run flow: current step, direction of travel and the collected answers.
@Observable
final class OnboardingStore {
    enum Direction {
        case forward
        case backward
    }

    private(set) var index: Int = 0
    private(set) var direction: Direction = .forward
    var answers = OnboardingAnswers()

    private let steps: [OnboardingStep] = OnboardingStep.allCases

    var step: OnboardingStep { steps[index] }

    /// 0...1 fill of the top progress bar. Counted from the hero so the bar starts nearly empty.
    var progress: Double {
        let first = OnboardingStep.hero.rawValue
        let last = OnboardingStep.paywall.rawValue
        let position = max(0, index - first)
        return min(1, (Double(position) + 1) / Double(last - first + 1))
    }

    func next() {
        guard index < steps.count - 1 else { return }
        direction = .forward
        withAnimation(.easeInOut(duration: 0.34)) {
            index += 1
        }
    }

    func back() {
        guard index > 0 else { return }
        direction = .backward
        withAnimation(.easeInOut(duration: 0.34)) {
            index -= 1
        }
    }

    func jump(to step: OnboardingStep) {
        guard let target = steps.firstIndex(of: step) else { return }
        direction = target >= index ? .forward : .backward
        withAnimation(.easeInOut(duration: 0.34)) {
            index = target
        }
    }

    /// Records a single-choice answer and moves on after a short beat so the selection reads.
    func choose(_ value: String, into keyPath: WritableKeyPath<OnboardingAnswers, String?>) {
        answers[keyPath: keyPath] = value
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(260))
            next()
        }
    }

    func toggle(_ value: String, in keyPath: WritableKeyPath<OnboardingAnswers, [String]>, exclusive: String? = nil) {
        var list = answers[keyPath: keyPath]
        if let exclusive, value == exclusive {
            list = list.contains(value) ? [] : [value]
        } else {
            if let exclusive { list.removeAll { $0 == exclusive } }
            if let found = list.firstIndex(of: value) {
                list.remove(at: found)
            } else {
                list.append(value)
            }
        }
        answers[keyPath: keyPath] = list
    }
}

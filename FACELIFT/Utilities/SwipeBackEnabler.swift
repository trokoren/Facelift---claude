import SwiftUI
import UIKit

/// Keeps the edge swipe-back gesture working on stacks whose navigation bar is hidden,
/// without overriding any UIKit navigation behaviour. Attach once to a stack's root view.
struct SwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller {
        Controller()
    }

    func updateUIViewController(_ uiViewController: Controller, context: Context) {}

    final class Controller: UIViewController, UIGestureRecognizerDelegate {
        private weak var attachedNavigation: UINavigationController?

        override func viewDidLoad() {
            super.viewDidLoad()
            view.isUserInteractionEnabled = false
            view.backgroundColor = .clear
        }

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            attach()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            attach()
        }

        private func attach() {
            guard let navigation = navigationController,
                  let pop = navigation.interactivePopGestureRecognizer else { return }
            attachedNavigation = navigation
            pop.isEnabled = true
            if pop.delegate !== self {
                pop.delegate = self
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (attachedNavigation?.viewControllers.count ?? 0) > 1
        }
    }
}

extension View {
    /// Re-enables swipe-back for a navigation stack with a hidden bar.
    func swipeBackEnabled() -> some View {
        background(SwipeBackEnabler().frame(width: 0, height: 0).allowsHitTesting(false))
    }
}

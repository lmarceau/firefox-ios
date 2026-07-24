// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// DEMO FILE - intentionally violates docs/architecture-guidelines.md.
// Used to verify the Claude architecture review workflow catches violations.
// Do not merge this file to main.

import UIKit
import Foundation

// General guidelines: global function.
func demoGlobalHelper() -> String {
    return "hello"
}

// General guidelines: singleton pattern.
final class DemoManager {
    static let shared = DemoManager()
    var latestValue = 0
    private init() {}
}

// General guidelines: static func that hides a dependency and skips DI.
final class DemoAnalytics {
    static func track(event: String) {
        let url = URL(string: "https://example.com/track?event=\(event)")!
        URLSession.shared.dataTask(with: url) { _, _, _ in }.resume()
    }
}

// Modern concurrency: @unchecked Sendable on a mutable class with no locking.
final class DemoCache: @unchecked Sendable {
    var items: [String: Any] = [:]
}

// Coordinators, Theming, Accessibility, Closures, Modern concurrency violations.
final class DemoScreenViewController: UIViewController {
    private let titleLabel = UILabel()
    private let goButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Theming: hardcoded UIColor and system color instead of theme tokens.
        view.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        titleLabel.textColor = .red

        // Accessibility: no accessibilityLabel, no accessibilityIdentifier,
        // hardcoded font size, fixed frame that breaks Dynamic Type.
        titleLabel.text = "Hello"
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.frame = CGRect(x: 16, y: 100, width: 200, height: 24)
        view.addSubview(titleLabel)

        goButton.setTitle("Continue", for: .normal)
        goButton.addTarget(self, action: #selector(didTapGo), for: .touchUpInside)
        view.addSubview(goButton)
    }

    @objc
    private func didTapGo() {
        // Coordinators: view controller performing navigation directly instead of
        // delegating to a coordinator or dispatching a NavigationBrowserAction.
        let next = UIViewController()
        navigationController?.pushViewController(next, animated: true)

        let modal = UIViewController()
        present(modal, animated: true, completion: nil)
    }

    // Modern concurrency: Task { } inside an already-async function, GCD mixed
    // with Swift concurrency in the same call chain.
    // Closures: missing [weak self] in Task and the DispatchQueue closures.
    func refresh() async {
        Task {
            DispatchQueue.global().async {
                let payload = "refreshed"
                DispatchQueue.main.async {
                    self.titleLabel.text = payload
                }
            }
        }
    }
}

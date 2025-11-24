import UIKit

/// Layer B: The bottom UIKit layer containing interactive UIKit controls.
/// This layer fills the screen and sits behind the SwiftUI overlay.
/// It demonstrates that touches can pass through the SwiftUI layer to interact with these controls.
class LayerBViewController: UIViewController {
    private let statusLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        // Set distinctive background color for Layer B
        view.backgroundColor = UIColor(red: 0.95, green: 0.85, blue: 0.7, alpha: 1.0)

        // Configure the status label
        statusLabel.text = "Tap the button below\nto interact with Layer B"
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        statusLabel.textColor = .darkGray
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        // Configure the action button
        var buttonConfig = UIButton.Configuration.filled()
        buttonConfig.title = "Tap Me (Layer B)"
        buttonConfig.baseBackgroundColor = UIColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1.0)
        buttonConfig.baseForegroundColor = .white
        actionButton.configuration = buttonConfig
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        view.addSubview(actionButton)

        // Layout constraints
        NSLayoutConstraint.activate([
            // Status label centered horizontally, in the upper third
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

            // Action button centered both horizontally and vertically
            actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            actionButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 200),
            actionButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    @objc private func buttonTapped() {
        statusLabel.text = "Button tapped!\nTouches from Layer A\npassed through to Layer B"
        statusLabel.textColor = UIColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0)

        // Reset after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.resetStatus()
        }
    }

    private func resetStatus() {
        statusLabel.text = "Tap the button below\nto interact with Layer B"
        statusLabel.textColor = .darkGray
    }
}

//
//  LogDetailViewController.swift
//  NetworkInspector
//
//  Created by Revanth A on 01/01/26.
//


import UIKit

final class LogDetailViewController: UIViewController {

    private let log: NetworkLog
    private let segmentedControl = UISegmentedControl(items: ["Request", "Status", "Response"])
    private let containerView = UIView()
    private lazy var tabViewControllers: [UIViewController] = [
        RequestTabViewController(log: log),
        ResponseStatusTabViewController(log: log),
        ResponseBodyTabViewController(log: log)
    ]
    private var currentChild: UIViewController?

    init(log: NetworkLog) {
        self.log = log
        super.init(nibName: nil, bundle: nil)
        title = LogDetailViewController.titleForEndpoint(from: log.request.url)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavigationItems()
        setupSegmentedControl()
        setupContainer()
        showChild(at: 0)
    }
}

private extension LogDetailViewController {

    static func titleForEndpoint(from url: URL?) -> String {
        guard let url else { return "Request" }
        let path = url.path
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return trimmed.isEmpty ? (url.host ?? "Request") : trimmed
    }

    func setupNavigationItems() {
        let menu = UIMenu(children: [
            UIAction(title: "Copy cURL", image: UIImage(systemName: "terminal")) { [weak self] _ in
                self?.copyCurl()
            },
            UIAction(title: "Copy Auth Token", image: UIImage(systemName: "key")) { [weak self] _ in
                self?.copyAuthToken()
            }
        ])

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Copy",
            image: nil,
            primaryAction: nil,
            menu: menu
        )
    }

    func setupSegmentedControl() {
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(onSegmentChanged), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedControl)

        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    func setupContainer() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc
    func onSegmentChanged() {
        showChild(at: segmentedControl.selectedSegmentIndex)
    }

    func showChild(at index: Int) {
        guard index >= 0, index < tabViewControllers.count else { return }
        let newChild = tabViewControllers[index]
        if newChild === currentChild { return }

        if let currentChild {
            currentChild.willMove(toParent: nil)
            currentChild.view.removeFromSuperview()
            currentChild.removeFromParent()
        }

        addChild(newChild)
        newChild.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(newChild.view)

        NSLayoutConstraint.activate([
            newChild.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            newChild.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            newChild.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            newChild.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])

        newChild.didMove(toParent: self)
        currentChild = newChild
    }

    func copyCurl() {
        UIPasteboard.general.string = buildCurlCommand()
        showCopiedToast(message: "cURL command copied to clipboard.")
    }

    func copyAuthToken() {
        if let token = extractAuthToken() {
            UIPasteboard.general.string = token
            showCopiedToast(message: "Auth token copied to clipboard.")
        } else {
            showCopiedToast(title: "No Token", message: "No Authorization header on this request.")
        }
    }

    func extractAuthToken() -> String? {
        let authValue = log.request.headers.first { $0.key.caseInsensitiveCompare("Authorization") == .orderedSame }?.value
        guard let raw = authValue?.trimmingCharacters(in: .whitespaces), !raw.isEmpty else {
            return nil
        }

        let lowered = raw.lowercased()
        for scheme in ["bearer ", "token ", "basic "] {
            if lowered.hasPrefix(scheme) {
                return String(raw.dropFirst(scheme.count)).trimmingCharacters(in: .whitespaces)
            }
        }
        return raw
    }

    func showCopiedToast(title: String = "Copied", message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            alert.dismiss(animated: true)
        }
    }

    func buildCurlCommand() -> String {
        guard let url = log.request.url?.absoluteString else {
            return "curl"
        }

        var parts: [String] = [
            "curl",
            "-X",
            log.request.method.rawValue
        ]

        let headers = log.request.headers.sorted { $0.key < $1.key }
        for header in headers {
            let headerValue = "\(header.key): \(header.value)"
            parts.append("-H")
            parts.append("'\(shellEscapeSingleQuotes(headerValue))'")
        }

        if let body = log.request.body {
            let bodyString = String(decoding: body, as: UTF8.self)
            if !bodyString.isEmpty {
                parts.append("--data-binary")
                parts.append("'\(shellEscapeSingleQuotes(bodyString))'")
            }
        }

        parts.append("'\(shellEscapeSingleQuotes(url))'")
        return parts.joined(separator: " ")
    }

    func shellEscapeSingleQuotes(_ value: String) -> String {
        value.replacingOccurrences(of: "'", with: "'\"'\"'")
    }
}

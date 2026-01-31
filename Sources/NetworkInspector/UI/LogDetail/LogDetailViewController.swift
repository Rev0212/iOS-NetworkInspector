//
//  LogDetailViewController.swift
//  NetworkInspector
//
//  Created by Revanth A on 01/01/26.
//


import UIKit

final class LogDetailViewController: UIViewController {

    private let log: NetworkLog

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
        setupTabs()
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Copy cURL",
            style: .plain,
            target: self,
            action: #selector(copyCurl)
        )
    }

    func setupTabs() {
        let requestVC = RequestTabViewController(log: log)
        requestVC.tabBarItem = UITabBarItem(
            title: "Request",
            image: UIImage(systemName: "arrow.up"),
            tag: 0
        )

        let statusVC = ResponseStatusTabViewController(log: log)
        statusVC.tabBarItem = UITabBarItem(
            title: "Status",
            image: UIImage(systemName: "info.circle"),
            tag: 1
        )

        let bodyVC = ResponseBodyTabViewController(log: log)
        bodyVC.tabBarItem = UITabBarItem(
            title: "Response",
            image: UIImage(systemName: "doc.text"),
            tag: 2
        )

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [
            requestVC,
            statusVC,
            bodyVC
        ]

        // 🔴 1. Disable translucency (major glossy source)
        tabBarController.tabBar.isTranslucent = false
        tabBarController.tabBar.backgroundColor = .white

        // 🔴 2. Force opaque tab bar appearance (iOS 15+)
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white

            appearance.stackedLayoutAppearance.normal.iconColor = .darkGray
            appearance.stackedLayoutAppearance.selected.iconColor = .black
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.darkGray
            ]
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor.black
            ]

            tabBarController.tabBar.standardAppearance = appearance
            tabBarController.tabBar.scrollEdgeAppearance = appearance
        }

        // 🔴 3. Proper containment + layout
        addChild(tabBarController)
        tabBarController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabBarController.view)

        NSLayoutConstraint.activate([
            tabBarController.view.topAnchor.constraint(equalTo: view.topAnchor),
            tabBarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tabBarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        tabBarController.didMove(toParent: self)
    }

    @objc
    func copyCurl() {
        let curlCommand = buildCurlCommand()
        UIPasteboard.general.string = curlCommand

        let alert = UIAlertController(
            title: "Copied",
            message: "cURL command copied to clipboard.",
            preferredStyle: .alert
        )
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

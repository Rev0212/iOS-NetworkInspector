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
        title = log.request.url?.lastPathComponent ?? "Request"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTabs()
    }
}

private extension LogDetailViewController {

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
}

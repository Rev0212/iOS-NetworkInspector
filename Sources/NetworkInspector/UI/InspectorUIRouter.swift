//
//  InspectorUIRouter.swift
//  NetworkInspector
//
//  Created by Revanth A on 01/01/26.
//


import UIKit

enum InspectorUIRouter {
    
    private static var isPresenting = false

    static func presentLogList() {
        guard !isPresenting else { return }
        guard let topVC = topViewController() else {
            assertionFailure("No top view controller found")
            return
        }

        let logListVC = LogListViewController()
        let nav = UINavigationController(rootViewController: logListVC)
        nav.modalPresentationStyle = .pageSheet

        topVC.present(nav, animated: true)
    }

    private static func topViewController(
        base: UIViewController? = UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    ) -> UIViewController? {

        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }

        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }

        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }

        return base
    }
}

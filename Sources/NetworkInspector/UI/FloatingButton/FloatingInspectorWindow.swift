//
//  FloatingInspectorWindow.swift
//  NetworkInspector
//
//  Created by Revanth A on 01/01/26.
//


import UIKit

import UIKit

final class FloatingInspectorWindow {

    static let shared = FloatingInspectorWindow()

    private var window: PassThroughWindow?

    private init() {}

    func show() {
        guard window == nil else {
            print("⚠️ Floating inspector already shown")
            return
        }

        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first
        else {
            print("❌ No UIWindowScene found")
            return
        }

        print("✅ Installing Floating Inspector Window")

        let window = PassThroughWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.windowLevel = .statusBar + 1
        window.backgroundColor = .clear

        let rootVC = UIViewController()
        rootVC.view.backgroundColor = .clear

        let button = FloatingInspectorButton()
        rootVC.view.addSubview(button)

        window.rootViewController = rootVC
        window.isHidden = false

        self.window = window
    }

    func hide() {
        window?.isHidden = true
        window = nil
    }
}

//
//  ShakeWindowInstaller.swift
//  NetworkInspector
//
//  Created by Revanth A on 01/01/26.
//


import UIKit

enum ShakeWindowInstaller {

    private static var installedWindow: ShakeDetectingWindow?

    static func install() {
        guard installedWindow == nil else { return }

        guard
            let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let existingWindow = scene.windows.first(where: { $0.isKeyWindow })
        else {
            return
        }

        let window = ShakeDetectingWindow(windowScene: scene)
        window.frame = existingWindow.frame
        window.rootViewController = existingWindow.rootViewController

        // Keep same level so UI is untouched
        window.windowLevel = existingWindow.windowLevel

        window.isHidden = false
        window.makeKey()

        installedWindow = window
    }
}

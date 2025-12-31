//
//  ShakeDetectingWindow.swift
//  NetworkInspector
//
//  Created by Revanth A on 01/01/26.
//


import UIKit

final class ShakeDetectingWindow: UIWindow {

    override var canBecomeFirstResponder: Bool {
        true
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        becomeFirstResponder()
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }

        print("📳 SHAKE DETECTED")
        InspectorUIRouter.presentLogList()
    }
}

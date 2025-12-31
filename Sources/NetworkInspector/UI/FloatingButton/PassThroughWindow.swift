//
//  PassThroughWindow.swift
//  NetworkInspector
//
//  Created by Revanth A on 01/01/26.
//


import UIKit

import UIKit

final class PassThroughWindow: UIWindow {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)

        if hitView === rootViewController?.view {
            return nil
        }
        return hitView
    }
}

//
//  FloatingInspectorButton.swift
//  NetworkInspector
//
//  Created by Revanth A on 01/01/26.
//


import UIKit

final class FloatingInspectorButton: UIButton {

    init() {
        super.init(frame: CGRect(x: 20, y: 200, width: 56, height: 56))

        backgroundColor = .black
        setTitle("📡", for: .normal)
        titleLabel?.font = .systemFont(ofSize: 24)
        layer.cornerRadius = 28
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 0, height: 2)

        addTarget(self, action: #selector(onTap), for: .touchUpInside)
        addPanGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTap() {
        InspectorUIRouter.presentLogList()
    }

    private func addPanGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onPan))
        addGestureRecognizer(pan)
    }

    @objc private func onPan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = superview else { return }

        let translation = gesture.translation(in: superview)

        // Move freely while dragging
        center = CGPoint(
            x: center.x + translation.x,
            y: center.y + translation.y
        )

        gesture.setTranslation(.zero, in: superview)

        // When gesture ends, snap to edge
        if gesture.state == .ended || gesture.state == .cancelled {
            snapToNearestEdge(in: superview)
        }
    }
    
    private func snapToNearestEdge(in superview: UIView) {
        let padding: CGFloat = 16

        let leftX = padding + bounds.width / 2
        let rightX = superview.bounds.width - padding - bounds.width / 2

        let targetX: CGFloat =
            center.x < superview.bounds.midX ? leftX : rightX

        let minY = padding + bounds.height / 2
        let maxY = superview.bounds.height - padding - bounds.height / 2

        let targetY = min(max(center.y, minY), maxY)

        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.5,
                       options: [.curveEaseOut]) {
            self.center = CGPoint(x: targetX, y: targetY)
        }
    }
}

// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public enum LeapInspector {

    public enum ResponseViewMode {
        case tree
        case raw
    }

    private static var isEnabled = false

    public static var responseViewMode: ResponseViewMode = .tree

    public static func enable(baseURLs: [String] = []) {
        guard !isEnabled else { return }
        isEnabled = true
        NetworkInterceptor.setAllowedBaseURLs(baseURLs)
        NetworkInterceptor.register()
    }
    
    public static func disable() {
        guard isEnabled else { return }
        isEnabled = false
        NetworkInterceptor.unregister()
    }
    
    public static func enableShakeToOpen() {
        ShakeWindowInstaller.install()
    }
    
    public static func enableFloatingButton() {
        FloatingInspectorWindow.shared.show()
    }
    
    public static func disableFloatingButton() {
        FloatingInspectorWindow.shared.hide()
    }
}

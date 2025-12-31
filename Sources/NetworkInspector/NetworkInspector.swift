// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public enum NetworkInspector {
    
    private static var isEnabled = false
    
    //Enables network inspection globally.
        public static func enable() {
            guard !isEnabled else { return }
            isEnabled = true
            NetworkInterceptor.register()
        }

    //Disables network inspection and restores default behavior.
        public static func disable() {
            guard isEnabled else { return }
            isEnabled = false
            NetworkInterceptor.unregister()
        }
}

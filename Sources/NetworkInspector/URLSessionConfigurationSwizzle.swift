//
//  URLSessionConfigurationSwizzle.swift
//  NetworkInspector
//
//  Created by Revanth A on 26/08/26.
//


import Foundation
import ObjectiveC

extension URLSessionConfiguration {

    private static var isSwizzled = false

    @objc dynamic var inspector_protocolClasses: [AnyClass]? {
        var classes = self.inspector_protocolClasses ?? []
        if !classes.contains(where: { $0 == InspectorURLProtocol.self }) {
            classes.insert(InspectorURLProtocol.self, at: 0)
        }
        return classes
    }

    static func installInspectorSwizzle() {
        guard !isSwizzled else { return }

        guard
            let original = class_getInstanceMethod(
                URLSessionConfiguration.self,
                #selector(getter: URLSessionConfiguration.protocolClasses)
            ),
            let replacement = class_getInstanceMethod(
                URLSessionConfiguration.self,
                #selector(getter: URLSessionConfiguration.inspector_protocolClasses)
            )
        else { return }

        method_exchangeImplementations(original, replacement)
        isSwizzled = true
    }
}

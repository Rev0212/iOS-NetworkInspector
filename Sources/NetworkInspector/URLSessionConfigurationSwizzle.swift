//
//  URLSessionConfigurationSwizzle.swift
//  NetworkInspector
//
//  Created by Revanth A on 26/08/26.
//


import Foundation
import ObjectiveC

extension URLSessionConfiguration {

    /// `URLProtocol.registerClass` is only consulted by `NSURLConnection` and `URLSession.shared`.
    /// A session built from its own configuration — Ktor's Darwin engine, Alamofire, most embedded
    /// SDKs — ignores that registry entirely and only reads its own `protocolClasses`.
    ///
    /// Swizzling the instance `protocolClasses` getter does not work here: `URLSessionConfiguration`
    /// is a class cluster, so `default` returns a private `__NSCFURLSessionConfiguration` whose own
    /// override wins over anything exchanged on this class. The factory class methods are the one
    /// place every such configuration is guaranteed to pass through.
    static func installInspectorSwizzle() {
        _ = installOnce
    }

    /// A `static let` is initialised exactly once and is thread-safe, so concurrent callers block
    /// until the exchange has actually landed. A plain bool flag would let a second caller return
    /// early while the first was still mid-swizzle.
    private static let installOnce: Void = {
        exchangeClassMethod(
            #selector(getter: URLSessionConfiguration.default),
            with: #selector(URLSessionConfiguration.inspector_defaultSessionConfiguration)
        )
        exchangeClassMethod(
            #selector(getter: URLSessionConfiguration.ephemeral),
            with: #selector(URLSessionConfiguration.inspector_ephemeralSessionConfiguration)
        )
    }()

    private static func exchangeClassMethod(_ original: Selector, with replacement: Selector) {
        guard
            let originalMethod = class_getClassMethod(URLSessionConfiguration.self, original),
            let replacementMethod = class_getClassMethod(URLSessionConfiguration.self, replacement)
        else { return }

        method_exchangeImplementations(originalMethod, replacementMethod)
    }

    // The implementations are exchanged, so these calls land on the originals.
    @objc private class func inspector_defaultSessionConfiguration() -> URLSessionConfiguration {
        inspector_defaultSessionConfiguration().addingInspectorProtocol()
    }

    @objc private class func inspector_ephemeralSessionConfiguration() -> URLSessionConfiguration {
        inspector_ephemeralSessionConfiguration().addingInspectorProtocol()
    }

    private func addingInspectorProtocol() -> URLSessionConfiguration {
        var classes = protocolClasses ?? []
        guard !classes.contains(where: { $0 == InspectorURLProtocol.self }) else { return self }
        classes.insert(InspectorURLProtocol.self, at: 0)
        protocolClasses = classes
        return self
    }
}

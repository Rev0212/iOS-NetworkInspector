//
//  NetworkInterceptor.swift
//  NetworkInspector
//
//  Created by Revanth A on 01/01/26.
//


import Foundation

final class NetworkInterceptor {

    private static var allowedBaseURLs: [String] = []

    static func register() {
        URLProtocol.registerClass(InspectorURLProtocol.self)
    }

    static func unregister() {
        URLProtocol.unregisterClass(InspectorURLProtocol.self)
    }

    static func setAllowedBaseURLs(_ urls: [String]) {
        allowedBaseURLs = urls
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { normalizeBaseURL($0) }
    }

    static func getAllowedBaseURLs() -> [String] {
        allowedBaseURLs
    }

    static func shouldIntercept(_ url: URL?) -> Bool {
        guard let absoluteString = url?.absoluteString.lowercased() else { return false }
        guard !allowedBaseURLs.isEmpty else { return true }

        return allowedBaseURLs.contains { absoluteString.hasPrefix($0) }
    }

    private static func normalizeBaseURL(_ url: String) -> String {
        var normalized = url.lowercased()
        while normalized.hasSuffix("/") {
            normalized.removeLast()
        }
        return normalized
    }
}

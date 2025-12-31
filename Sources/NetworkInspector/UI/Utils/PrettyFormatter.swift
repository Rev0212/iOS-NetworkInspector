//
//  PrettyFormatter.swift
//  NetworkInspector
//
//  Created by Revanth A on 01/01/26.
//


import Foundation

enum PrettyFormatter {

    static func prettyJSON(from data: Data) -> String {
        guard
            let object = try? JSONSerialization.jsonObject(with: data),
            let prettyData = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .sortedKeys]
            ),
            let string = String(data: prettyData, encoding: .utf8)
        else {
            // Fallback: raw string
            return String(decoding: data, as: UTF8.self)
        }

        return string
    }

    static func prettyHeaders(_ headers: [String: String]) -> String {
        headers
            .sorted { $0.key < $1.key }
            .map { "\($0.key): \($0.value)" }
            .joined(separator: "\n")
    }
}

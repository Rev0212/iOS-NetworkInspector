//
//  NetworkLogBuilder.swift
//  NetworkInspector
//
//  Created by Revanth A on 01/01/26.
//


import Foundation

final class NetworkLogBuilder {

    private let id = UUID()


    private let maxCaptureSize = 1_000_000 // 1 MB

    // MARK: - Request
    private var requestInfo: RequestInfo?

    // MARK: - Response
    private var statusCode: Int?
    private var responseHeaders: [String: String]?
    private var responseBody = Data()
    private var error: Error?

    // MARK: - Timing
    private var startTime: Date?
    private var endTime: Date?

    // MARK: - Capture points

    func captureRequest(_ request: URLRequest) {
        guard requestInfo == nil else { return }

        let method: HTTPMethod =
            request.httpMethod.flatMap(HTTPMethod.init(rawValue:)) ?? .GET

        requestInfo = RequestInfo(
            url: request.url,
            method: method,
            headers: request.allHTTPHeaderFields ?? [:],
            body: request.httpBody
        )

        startTime = Date()
    }

    func captureResponse(_ response: HTTPURLResponse) {
        statusCode = response.statusCode

        responseHeaders = response.allHeaderFields.reduce(into: [:]) {
            if let key = $1.key as? String {
                $0[key] = String(describing: $1.value)
            }
        }
    }

    func appendResponseData(_ data: Data) {
        guard responseBody.count < maxCaptureSize else { return }

        let remaining = maxCaptureSize - responseBody.count
        responseBody.append(data.prefix(remaining))
    }

    func captureCompletion(error: Error?) {
        self.error = error
        endTime = Date()
    }

    // MARK: - Build final log

    func build() -> NetworkLog? {
        guard
            let requestInfo,
            let startTime,
            let endTime
        else {
            return nil
        }

        let timing = TimingInfo(
            startTime: startTime,
            endTime: endTime,
            duration: endTime.timeIntervalSince(startTime)
        )

        let response = ResponseInfo(
            statusCode: statusCode,
            headers: responseHeaders,
            body: responseBody.isEmpty ? nil : responseBody,
            error: error
        )

        return NetworkLog(
            id: id,
            request: requestInfo,
            response: response,
            timing: timing
        )
    }
}


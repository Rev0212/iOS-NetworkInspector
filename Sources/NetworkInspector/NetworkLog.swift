//
//  NetworkLog.swift
//  NetworkInspector
//
//  Created by Revanth A on 01/01/26.
//

import Foundation

struct NetworkLog {
    let id: UUID
    let request: RequestInfo
    let response: ResponseInfo
    let timing: TimingInfo
}

struct RequestInfo {
    let url: URL?
    let method: HTTPMethod
    let headers: [String: String]
    let body: Data?
}

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS
}

struct ResponseInfo {
    let statusCode: Int?
    let headers: [String: String]?
    let body: Data?
    let error: Error?
}


struct TimingInfo {
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
}

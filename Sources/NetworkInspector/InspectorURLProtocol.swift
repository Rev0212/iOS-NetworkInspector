//
//  InspectorURLProtocol.swift
//  NetworkInspector
//
//  Created by Revanth A on 01/01/26.
//


import Foundation

final class InspectorURLProtocol: URLProtocol {

    private static let handledKey = "NetworkInspectorHandled"
    
    private let logBuilder = NetworkLogBuilder()
    
    private var dataTask: URLSessionDataTask?

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    override class func canInit(with request: URLRequest) -> Bool {
        if URLProtocol.property(forKey: handledKey, in: request) != nil {
            return false
        }

        guard let scheme = request.url?.scheme else { return false }
        return scheme == "http" || scheme == "https"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let mutableRequest =
                (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutableRequest)

        let bodyData = materializeBodyIfNeeded(in: mutableRequest) ?? mutableRequest.httpBody
        logBuilder.captureRequest(mutableRequest as URLRequest, bodyOverride: bodyData)

        dataTask = session.dataTask(with: mutableRequest as URLRequest)
        
        dataTask?.resume()
    }

    override func stopLoading() {
        dataTask?.cancel()
        dataTask = nil
    }

    func materializeBodyIfNeeded(in request: NSMutableURLRequest) -> Data? {
        guard request.httpBody == nil, let stream = request.httpBodyStream else { return nil }

        stream.open()
        defer { stream.close() }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        var read = stream.read(&buffer, maxLength: buffer.count)

        while read > 0 {
            data.append(buffer, count: read)
            read = stream.read(&buffer, maxLength: buffer.count)
        }

        if !data.isEmpty {
            request.httpBody = data
            request.httpBodyStream = InputStream(data: data)

            if request.value(forHTTPHeaderField: "Content-Length") == nil {
                request.setValue(String(data.count), forHTTPHeaderField: "Content-Length")
            }
        }
        return data.isEmpty ? nil : data
    }
}

extension InspectorURLProtocol: URLSessionDataDelegate {

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        
        if let httpResponse = response as? HTTPURLResponse {
                logBuilder.captureResponse(httpResponse)
            }
        
        client?.urlProtocol(self,
                             didReceive: response,
                             cacheStoragePolicy: .notAllowed)
        completionHandler(.allow)
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        logBuilder.appendResponseData(data)
        client?.urlProtocol(self, didLoad: data)
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        
        logBuilder.captureCompletion(error: error)
        
        if let log = logBuilder.build() {
                NetworkLogStore.shared.add(log)
            }
        
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        guard let client else {
            completionHandler(request)
            return
        }

        let redirectRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        URLProtocol.removeProperty(forKey: Self.handledKey, in: redirectRequest)
        client.urlProtocol(self, wasRedirectedTo: redirectRequest as URLRequest, redirectResponse: response)
        completionHandler(nil)
    }
}



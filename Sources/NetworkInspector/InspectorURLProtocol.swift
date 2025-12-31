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
        logBuilder.captureRequest(request)
        
        guard let mutableRequest =
                (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutableRequest)

        dataTask = session.dataTask(with: mutableRequest as URLRequest)
        
        dataTask?.resume()
    }

    override func stopLoading() {
        dataTask?.cancel()
        dataTask = nil
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
}



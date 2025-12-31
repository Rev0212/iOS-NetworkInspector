//
//  NetworkInterceptor.swift
//  NetworkInspector
//
//  Created by Revanth A on 01/01/26.
//


import Foundation

final class NetworkInterceptor {

    static func register() {
        URLProtocol.registerClass(InspectorURLProtocol.self)
    }

    static func unregister() {
        URLProtocol.unregisterClass(InspectorURLProtocol.self)
    }
}

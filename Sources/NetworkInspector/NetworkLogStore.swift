//
//  NetworkLogStore.swift
//  NetworkInspector
//
//  Created by Revanth A on 01/01/26.
//

import Foundation

final class NetworkLogStore {
    
    static let shared = NetworkLogStore()
    private init() {}
    
    // MARK: - Policy
    private let maxLogCount = 300
    
    // MARK: - Storage
    private var logs: [NetworkLog] = []
    
    private let queue = DispatchQueue(
        label: "com.networkinspector.logstore.queue",
        qos: .utility
    )
    
    func add(_ log: NetworkLog) {
        queue.async {
            // Newest first
            self.logs.insert(log, at: 0)
            
            // Enforce max size
            if self.logs.count > self.maxLogCount {
                self.logs.removeLast(self.logs.count - self.maxLogCount)
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .networkLogStoreDidUpdate,
                    object: nil
                )
            }
        }
    }
    
    func getAllLogs() -> [NetworkLog] {
        queue.sync {
            logs
        }
    }
    
    func clear() {
        queue.async {
            self.logs.removeAll()
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .networkLogStoreDidUpdate,
                    object: nil
                )
            }
        }
    }
}

extension Notification.Name {
    static let networkLogStoreDidUpdate =
    Notification.Name("NetworkLogStoreDidUpdate")
}

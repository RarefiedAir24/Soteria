//
//  MainActorMonitor.swift
//  soteria
//
//  Utility to monitor MainActor blocking during app startup
//

import Foundation
import SwiftUI

class MainActorMonitor {
    static let shared = MainActorMonitor()
    
    private var operationLog: [(timestamp: Date, operation: String, duration: TimeInterval?)] = []
    private let queue = DispatchQueue(label: "com.soteria.mainactormonitor", attributes: .concurrent)
    
    private init() {}
    
    func logOperation(_ operation: String, duration: TimeInterval? = nil) {
        queue.async(flags: .barrier) {
            let entry = (timestamp: Date(), operation: operation, duration: duration)
            self.operationLog.append(entry)
            
            let timeStr = String(format: "%.3f", entry.timestamp.timeIntervalSince1970.truncatingRemainder(dividingBy: 1000))
            if let duration = duration {
                print("📊 [MainActorMonitor] \(timeStr)s - \(operation) (took \(String(format: "%.3f", duration))s)")
            } else {
                print("📊 [MainActorMonitor] \(timeStr)s - \(operation)")
            }
        }
    }
    
    func logMainActorOperation<T>(_ operation: String, block: @MainActor () throws -> T) rethrows -> T {
        let startTime = Date()
        logOperation("START: \(operation)")
        defer {
            let duration = Date().timeIntervalSince(startTime)
            logOperation("END: \(operation)", duration: duration)
            if duration > 0.1 {
                print("⚠️ [MainActorMonitor] SLOW OPERATION: \(operation) took \(String(format: "%.3f", duration))s")
            }
        }
        return try block()
    }
    
    func getLog() -> [(timestamp: Date, operation: String, duration: TimeInterval?)] {
        return queue.sync {
            return operationLog
        }
    }
    
    func printSummary() {
        queue.sync {
            print("\n📊 [MainActorMonitor] ========== OPERATION SUMMARY ==========")
            for entry in operationLog {
                let timeSinceStart = entry.timestamp.timeIntervalSince(operationLog.first?.timestamp ?? Date())
                if let duration = entry.duration {
                    print("📊 [MainActorMonitor] +\(String(format: "%.3f", timeSinceStart))s: \(entry.operation) (took \(String(format: "%.3f", duration))s)")
                } else {
                    print("📊 [MainActorMonitor] +\(String(format: "%.3f", timeSinceStart))s: \(entry.operation)")
                }
            }
            print("📊 [MainActorMonitor] =========================================\n")
        }
    }
}

// Helper to measure MainActor operations
func measureMainActor<T>(_ operation: String, block: @MainActor () throws -> T) rethrows -> T {
    return try MainActorMonitor.shared.logMainActorOperation(operation, block: block)
}


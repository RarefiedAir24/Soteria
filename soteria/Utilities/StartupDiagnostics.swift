//
//  StartupDiagnostics.swift
//  soteria
//
//  Comprehensive diagnostic system for tracking app startup performance
//

import Foundation
import SwiftUI

class StartupDiagnostics {
    static let shared = StartupDiagnostics()
    
    private var events: [(timestamp: TimeInterval, event: String, thread: String)] = []
    private let startTime = Date()
    private let queue = DispatchQueue(label: "com.soteria.startupdiagnostics", attributes: .concurrent)
    private var monitoringTask: Task<Void, Never>?
    private var lastMainActorCheck: Date = Date()
    
    private init() {
        // CRITICAL: Do ABSOLUTELY NOTHING in init() - even logging can block MainActor
        // All logging is deferred to 60 seconds after startup
        // log("🚀 [StartupDiagnostics] App launch started")
        // CRITICAL: Disable MainActorMonitor - it's causing "unsafeForcedSync" warnings and contributing to blocking
        // startMainActorMonitoring()
    }
    
    // Monitor MainActor to detect blocking
    // CRITICAL: Use lower priority and less frequent checks to avoid contributing to blocking
    private func startMainActorMonitoring() {
        monitoringTask = Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            
            // Wait a bit before starting monitoring to avoid interfering with startup
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            var checkCount = 0
            while !Task.isCancelled {
                // Check every 1 second (less frequent to reduce overhead)
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                checkCount += 1
                
                // Capture checkCount in a local immutable variable to avoid concurrency issues
                let currentCheckCount = checkCount
                
                // Try to run on MainActor - if it's blocked, this will be delayed
                let checkStart = Date()
                await MainActor.run {
                    let checkDuration = Date().timeIntervalSince(checkStart)
                    let timestamp = Date().timeIntervalSince(self.startTime)
                    
                    // Only log if there's a significant delay
                    if checkDuration > 0.5 {
                        print("🔴 [MainActorMonitor] MainActor BLOCKED for \(String(format: "%.3f", checkDuration))s at \(String(format: "%.3f", timestamp))s (Check #\(currentCheckCount))")
                        
                        // Log full stack trace
                        print("  📍 Full Stack Trace:")
                        Thread.callStackSymbols.prefix(20).forEach { symbol in
                            print("    \(symbol)")
                        }
                        
                        // Log what's currently on MainActor
                        self.log("🔴 [MainActorMonitor] Block detected - check #\(currentCheckCount), duration: \(String(format: "%.3f", checkDuration))s")
                    }
                    self.lastMainActorCheck = Date()
                }
            }
        }
    }
    
    func stopMonitoring() {
        monitoringTask?.cancel()
    }
    
    func log(_ message: String) {
        let timestamp = Date().timeIntervalSince(startTime)
        let thread = Thread.isMainThread ? "Main" : "Background"
        
        queue.async(flags: .barrier) {
            self.events.append((timestamp: timestamp, event: message, thread: thread))
        }
        
        let timeStr = String(format: "%.3f", timestamp)
        print("⏱️ [\(timeStr)s] \(message) [\(thread)]")
    }
    
    func logServiceInit(_ serviceName: String, startTime: Date) {
        let duration = Date().timeIntervalSince(startTime)
        if duration > 0.01 {
            log("⚠️ [Service] \(serviceName).init() took \(String(format: "%.3f", duration))s (SLOW)")
        } else {
            log("✅ [Service] \(serviceName).init() completed (fast)")
        }
    }
    
    func logViewInit(_ viewName: String, startTime: Date) {
        let duration = Date().timeIntervalSince(startTime)
        if duration > 0.01 {
            log("⚠️ [View] \(viewName).init() took \(String(format: "%.3f", duration))s (SLOW)")
        } else {
            log("✅ [View] \(viewName).init() completed (fast)")
        }
    }
    
    func logMainActorBlock(_ operation: String, startTime: Date) {
        let duration = Date().timeIntervalSince(startTime)
        if duration > 0.1 {
            log("🔴 [MainActor] BLOCKED for \(String(format: "%.3f", duration))s during: \(operation)")
        }
    }
    
    func logServiceAccess(_ serviceName: String, startTime: Date) {
        let duration = Date().timeIntervalSince(startTime)
        if duration > 0.01 {
            log("⚠️ [ServiceAccess] \(serviceName).shared access took \(String(format: "%.3f", duration))s")
        } else {
            log("✅ [ServiceAccess] \(serviceName).shared access completed (fast)")
        }
    }
    
    func logImageLoad(_ imageName: String, startTime: Date) {
        let duration = Date().timeIntervalSince(startTime)
        if duration > 0.01 {
            log("⚠️ [ImageLoad] Loading '\(imageName)' took \(String(format: "%.3f", duration))s")
        }
    }
    
    func logUserDefaultsRead(_ key: String, startTime: Date) {
        let duration = Date().timeIntervalSince(startTime)
        if duration > 0.01 {
            log("⚠️ [UserDefaults] Reading '\(key)' took \(String(format: "%.3f", duration))s")
        }
    }
    
    func logRenderingPhase(_ phase: String) {
        log("🎨 [Rendering] \(phase)")
    }
    
    func printSummary() {
        queue.sync {
            print("\n" + "=".repeating(80))
            print("📊 STARTUP DIAGNOSTICS SUMMARY")
            print("=".repeating(80))
            
            var totalTime: TimeInterval = 0
            if let lastEvent = events.last {
                totalTime = lastEvent.timestamp
            }
            
            print("Total startup time: \(String(format: "%.3f", totalTime))s")
            print("\nTimeline:")
            
            for event in events {
                let timeStr = String(format: "%8.3f", event.timestamp)
                print("[\(timeStr)s] \(event.event) [\(event.thread)]")
            }
            
            // Identify slow operations
            print("\n⚠️ SLOW OPERATIONS (>0.1s):")
            var prevTime: TimeInterval = 0
            for event in events {
                let gap = event.timestamp - prevTime
                if gap > 0.1 {
                    print("  Gap of \(String(format: "%.3f", gap))s before: \(event.event)")
                }
                prevTime = event.timestamp
            }
            
            print("=".repeating(80) + "\n")
        }
    }
}

extension String {
    func repeating(_ count: Int) -> String {
        return String(repeating: self, count: count)
    }
}


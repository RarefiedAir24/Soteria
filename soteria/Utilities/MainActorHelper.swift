//
//  MainActorHelper.swift
//  Soteria
//
//  CRITICAL: Utility to ensure all MainActor operations are non-blocking
//  This prevents MainActor saturation and UI freezes
//

import Foundation

/// Helper to safely execute work on MainActor without blocking
enum MainActorHelper {
    /// Execute work on MainActor asynchronously (non-blocking)
    /// Use this instead of `await MainActor.run` for fire-and-forget operations
    static func async(_ work: @escaping @MainActor () -> Void) {
        DispatchQueue.main.async {
            work()
        }
    }
    
    /// Execute work on MainActor after a delay (non-blocking)
    static func asyncAfter(deadline: DispatchTime, _ work: @escaping @MainActor () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            work()
        }
    }
    
    /// Execute work on MainActor after a time interval (non-blocking)
    static func asyncAfter(seconds: TimeInterval, _ work: @escaping @MainActor () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            work()
        }
    }
    
    /// Safely read a value from MainActor (for async contexts)
    /// Use this when you need to return a value from MainActor in an async context
    static func read<T>(_ work: @escaping @MainActor () -> T) async -> T {
        return await MainActor.run {
            work()
        }
    }
    
    /// Batch multiple MainActor operations into a single dispatch
    /// This prevents multiple MainActor.run calls from queueing up
    static func batch(_ operations: [@MainActor () -> Void]) {
        DispatchQueue.main.async {
            for operation in operations {
                operation()
            }
        }
    }
}


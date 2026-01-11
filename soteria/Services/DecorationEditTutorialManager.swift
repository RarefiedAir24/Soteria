//
//  DecorationEditTutorialManager.swift
//  soteria
//
//  Manages the decoration edit tutorial state globally
//

import Foundation
import SwiftUI
import Combine

class DecorationEditTutorialManager: ObservableObject {
    static let shared = DecorationEditTutorialManager()
    
    @Published var showTutorial: Bool = false
    @Published var selectedItemId: String? = nil // ID of item being edited
    
    private init() {}
    
    func requestTutorial(for itemId: String) {
        DispatchQueue.main.async {
            self.selectedItemId = itemId
            self.showTutorial = true
        }
    }
    
    func dismissTutorial() {
        DispatchQueue.main.async {
            self.showTutorial = false
            // Keep selectedItemId so arrow pad can show
        }
    }
    
    func exitEditMode() {
        DispatchQueue.main.async {
            self.showTutorial = false
            self.selectedItemId = nil
        }
    }
}

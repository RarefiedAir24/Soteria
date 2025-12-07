//
//  PlaidLinkView.swift
//  rever
//
//  Created by Frank Schioppa on 12/7/25.
//

import SwiftUI
import UIKit
import LinkKit

// Plaid Link Handler
class PlaidLinkHandler: NSObject, PLKLinkViewControllerDelegate {
    var onSuccess: ((String, [String: Any]?) -> Void)?
    var onExit: ((Error?, [String: Any]?) -> Void)?
    
    func linkViewController(_ linkViewController: PLKLinkViewController, didSucceedWithPublicToken publicToken: String, metadata: [String : Any]?) {
        print("✅ [Plaid] Link successful! Public token: \(publicToken)")
        onSuccess?(publicToken, metadata)
    }
    
    func linkViewController(_ linkViewController: PLKLinkViewController, didExitWithError error: Error?, metadata: [String : Any]?) {
        if let error = error {
            print("❌ [Plaid] Link exited with error: \(error.localizedDescription)")
        } else {
            print("ℹ️ [Plaid] Link exited by user")
        }
        onExit?(error, metadata)
    }
    
    func linkViewController(_ linkViewController: PLKLinkViewController, didReceiveEvent event: String, metadata: [String : Any]?) {
        print("🔗 [Plaid] Event: \(event)")
    }
}

// Plaid Link Wrapper using UIViewRepresentable
struct PlaidLinkView: UIViewControllerRepresentable {
    let linkToken: String
    let onSuccess: (String, [String: Any]?) -> Void
    let onExit: (Error?, [String: Any]?) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let handler = PlaidLinkHandler()
        
        handler.onSuccess = onSuccess
        handler.onExit = onExit
        
        // Create Plaid Link configuration
        var linkConfiguration = PLKConfiguration(linkToken: linkToken) { success in
            if success {
                print("✅ [Plaid] Link configuration created successfully")
                // Create and present Plaid Link view controller
                let linkViewController = PLKLinkViewController(linkToken: linkToken, delegate: handler)
                DispatchQueue.main.async {
                    viewController.present(linkViewController, animated: true)
                }
            } else {
                print("❌ [Plaid] Failed to create link configuration")
                DispatchQueue.main.async {
                    onExit(NSError(domain: "PlaidLink", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize Plaid Link"]), nil)
                }
            }
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Update if needed
    }
}

// MARK: - Plaid Link SDK Integration
// Once CocoaPods is installed, uncomment the import and use this implementation:

/*
import LinkKit

class PlaidLinkHandler: NSObject, PLKLinkViewControllerDelegate {
    var onSuccess: ((String, [String: Any]?) -> Void)?
    var onExit: ((Error?, [String: Any]?) -> Void)?
    
    func linkViewController(_ linkViewController: PLKLinkViewController, didSucceedWithPublicToken publicToken: String, metadata: [String : Any]?) {
        onSuccess?(publicToken, metadata)
    }
    
    func linkViewController(_ linkViewController: PLKLinkViewController, didExitWithError error: Error?, metadata: [String : Any]?) {
        onExit?(error, metadata)
    }
    
    func linkViewController(_ linkViewController: PLKLinkViewController, didReceiveEvent event: String, metadata: [String : Any]?) {
        print("🔗 [Plaid] Event: \(event)")
    }
}

// Update makeUIViewController to use actual Plaid SDK:
func makeUIViewController(context: Context) -> UIViewController {
    let viewController = UIViewController()
    let handler = PlaidLinkHandler()
    
    handler.onSuccess = onSuccess
    handler.onExit = onExit
    
    var linkConfiguration = PLKConfiguration(linkToken: linkToken) { success in
        if success {
            let linkViewController = PLKLinkViewController(linkToken: linkToken, delegate: handler)
            viewController.present(linkViewController, animated: true)
        } else {
            onExit(NSError(domain: "PlaidLink", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize Plaid Link"]), nil)
        }
    }
    
    return viewController
}
*/


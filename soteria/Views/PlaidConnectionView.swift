//
//  PlaidConnectionView.swift
//  soteria
//
//  View for connecting bank accounts via Plaid
//

import SwiftUI
// import LinkKit  // Temporarily disabled - will implement lazy loading

struct PlaidConnectionView: View {
    @EnvironmentObject var plaidService: PlaidService
    @SwiftUI.Environment(\.dismiss) var dismiss: DismissAction
    
    @State private var isConnecting = false
    @State private var errorMessage: String? = nil
    @State private var showError = false
    @State private var linkToken: String? = nil
    @State private var showPlaidLink = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color.themePrimary)
                    
                    Text("Connect Your Accounts")
                        .font(.title.bold())
                    
                    Text("Enable automatic savings transfers when you choose protection")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // Benefits
                VStack(alignment: .leading, spacing: 16) {
                    BenefitRow(
                        icon: "arrow.right.circle.fill",
                        title: "Automatic Transfers",
                        description: "Money moves to savings when you unblock"
                    )
                    
                    BenefitRow(
                        icon: "eye.fill",
                        title: "See Your Progress",
                        description: "Track your savings balance in real-time"
                    )
                    
                    BenefitRow(
                        icon: "lock.shield.fill",
                        title: "Secure & Private",
                        description: "We never hold your money - it stays in your bank"
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Connect Button
                Button(action: {
                    Task {
                        await connectAccounts()
                    }
                }) {
                    HStack {
                        if isConnecting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Connect Accounts")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.themePrimary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isConnecting)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Bank Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Connection Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Failed to connect accounts")
            }
            .sheet(isPresented: $showPlaidLink) {
                if let linkToken = linkToken {
                    PlaidLinkView(
                        linkToken: linkToken,
                        onSuccess: { publicToken in
                            Task {
                                await exchangeToken(publicToken)
                            }
                        },
                        onExit: {
                            isConnecting = false
                        }
                    )
                }
            }
        }
    }
    
    private func connectAccounts() async {
        isConnecting = true
        errorMessage = nil
        
        do {
            // Step 1: Create link token
            let token = try await plaidService.createLinkToken()
            
            // Step 2: Open Plaid Link UI
            await MainActor.run {
                linkToken = token
                showPlaidLink = true
            }
            
        } catch {
            await MainActor.run {
                isConnecting = false
                // Provide more helpful error message
                let errorDesc = error.localizedDescription
                if errorDesc.contains("Internal server error") {
                    errorMessage = "Backend error. Please check:\n1. Lambda function is deployed\n2. Plaid credentials are configured\n3. CloudWatch logs for details"
                } else {
                    errorMessage = errorDesc
                }
                showError = true
            }
            print("❌ [PlaidConnectionView] Error: \(error)")
        }
    }
    
    private func exchangeToken(_ publicToken: String) async {
        do {
            try await plaidService.exchangePublicToken(publicToken)
            await MainActor.run {
                isConnecting = false
                showPlaidLink = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                isConnecting = false
                showPlaidLink = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Plaid Link View Wrapper

struct PlaidLinkView: UIViewControllerRepresentable {
    let linkToken: String
    let onSuccess: (String) -> Void
    let onExit: () -> Void
    
    func makeUIViewController(context: Context) -> PlaidLinkViewController {
        let viewController = PlaidLinkViewController(
            linkToken: linkToken,
            onSuccess: onSuccess,
            onExit: onExit
        )
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: PlaidLinkViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Plaid Link View Controller

class PlaidLinkViewController: UIViewController {
    let linkToken: String
    let onSuccess: (String) -> Void
    let onExit: () -> Void
    var linkHandler: Any? // Handler?  // Temporarily disabled
    
    init(linkToken: String, onSuccess: @escaping (String) -> Void, onExit: @escaping () -> Void) {
        self.linkToken = linkToken
        self.onSuccess = onSuccess
        self.onExit = onExit
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create Plaid Link configuration
        // TEMPORARILY DISABLED - will implement lazy loading
        /*
        var configuration = LinkTokenConfiguration(
            token: linkToken,
            onSuccess: { [weak self] linkSuccess in
                print("✅ [PlaidLinkViewController] Success: \(linkSuccess.publicToken)")
                self?.onSuccess(linkSuccess.publicToken)
                self?.dismiss(animated: true)
            }
        )
        
        configuration.onExit = { [weak self] linkExit in
            if let error = linkExit.error {
                print("⚠️ [PlaidLinkViewController] Exit with error: \(error.localizedDescription)")
            } else {
                print("⚠️ [PlaidLinkViewController] User exited")
            }
            self?.onExit()
            self?.dismiss(animated: true)
        }
        
        // Create and present Plaid Link
        let result = Plaid.create(configuration)
        switch result {
        case .success(let handler):
            linkHandler = handler
            linkHandler?.open(presentUsing: .viewController(self))
        case .failure(let error):
            print("❌ [PlaidLinkViewController] Failed to create Plaid Link: \(error)")
            onExit()
        }
        */
        print("⚠️ [PlaidLinkViewController] Plaid temporarily disabled - implementing lazy loading")
        onExit()
    }
    
    deinit {
        linkHandler = nil
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color.themePrimary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NavigationView {
        PlaidConnectionView()
            .environmentObject(PlaidService.shared)
    }
}


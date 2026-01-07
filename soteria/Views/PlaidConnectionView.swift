//
//  PlaidConnectionView.swift
//  soteria
//
//  View for connecting bank accounts via Plaid
//

import SwiftUI
#if canImport(LinkKit)
import LinkKit
#endif

struct PlaidConnectionView: View {
    @EnvironmentObject var plaidService: PlaidService
    @SwiftUI.Environment(\.dismiss) var dismiss: DismissAction
    
    @State private var isConnecting = false
    @State private var errorMessage: String? = nil
    @State private var showError = false
    @State private var linkToken: String? = nil
    @State private var showPlaidLink = false
    
    private var modeDescription: String {
        switch plaidService.savingsMode {
        case .automatic:
            return "Transfers available. You can initiate transfers to your savings account when you choose to save."
        case .virtual:
            return "Virtual savings mode. We'll track your savings, but transfers require a savings account."
        case .manual:
            return "Manual mode. Connect a savings account to enable transfers."
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if !plaidService.connectedAccounts.isEmpty {
                    // Show connected accounts
                    ScrollView {
                        VStack(spacing: 20) {
                            // Success Header
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.green)
                                
                                Text("Accounts Connected")
                                    .font(.title.bold())
                                
                                Text("\(plaidService.connectedAccounts.count) account\(plaidService.connectedAccounts.count == 1 ? "" : "s") successfully connected")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.top, 40)
                            
                            // Connected Accounts List
                            VStack(spacing: 12) {
                                ForEach(plaidService.connectedAccounts) { account in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(account.name)
                                                .font(.headline)
                                                .foregroundColor(.midnightSlate)
                                            
                                            Text("\(account.subtype.capitalized) ••••\(account.mask)")
                                                .font(.subheadline)
                                                .foregroundColor(.softGraphite)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.mistGray.opacity(0.3))
                                    )
                                }
                            }
                            .padding(.horizontal)
                            
                            // Mode Info
                            VStack(spacing: 8) {
                                Text("Savings Mode")
                                    .font(.headline)
                                    .foregroundColor(.midnightSlate)
                                
                                Text(modeDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.softGraphite)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.softGraphite.opacity(0.1))
                            )
                            .padding(.horizontal)
                            
                            Spacer()
                            
                            // Add More Accounts Button
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
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add More Accounts")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.softGraphite)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isConnecting)
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                } else {
                    // Show tutorial/connect screen
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color.softGraphite)
                            
                            Text("Connect Your Accounts")
                                .font(.title.bold())
                            
                            Text("Connect accounts to initiate transfers when you choose to save")
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
                                title: "User-Initiated Transfers",
                                description: "Initiate transfers to savings when you choose to save"
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
                            .background(Color.softGraphite)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isConnecting)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(plaidService.connectedAccounts.isEmpty ? "Bank Connection" : "Connected Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Load accounts when view appears
                Task {
                    await loadConnectedAccounts()
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
                    #if DEBUG
                    errorMessage = "Backend error. Please check:\n1. Local dev server is running (http://localhost:8000)\n2. Plaid credentials are configured in .env\n3. Server logs for details"
                    #else
                    errorMessage = "Backend error. Please check:\n1. Lambda function is deployed\n2. Plaid credentials are configured\n3. CloudWatch logs for details"
                    #endif
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
            // Reload accounts after successful exchange
            await loadConnectedAccounts()
            await MainActor.run {
                isConnecting = false
                showPlaidLink = false
                // Don't dismiss immediately - let user see the success screen
                // dismiss() will be called when they tap "Done"
            }
        } catch {
            await MainActor.run {
                isConnecting = false
                showPlaidLink = false
                errorMessage = error.localizedDescription
                showError = true
            }
            print("❌ [PlaidConnectionView] Exchange token error: \(error)")
        }
    }
    
    private func loadConnectedAccounts() async {
        // Fetch accounts from backend/DynamoDB
        await plaidService.fetchConnectedAccounts()
        print("🔍 [PlaidConnectionView] Connected accounts after fetch: \(plaidService.connectedAccounts.count)")
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
    #if canImport(LinkKit)
    var linkHandler: Handler?
    #endif
    
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
        
        view.backgroundColor = .systemBackground
        
        // Don't present LinkKit here - view is not in window hierarchy yet
        // Presentation will happen in viewDidAppear when view is visible
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        #if canImport(LinkKit)
        // Only present LinkKit once when view appears
        // Check if we've already initialized to prevent re-presentation
        guard linkHandler == nil else { return }
        
        // Initialize Plaid Link with LinkKit v4.7.9
        var linkConfiguration = LinkTokenConfiguration(
            token: linkToken,
            onSuccess: { [weak self] linkSuccess in
                guard let self = self else { return }
                // Extract public token from success result
                let publicToken = linkSuccess.publicToken
                print("✅ [PlaidLinkViewController] Link success - public token: \(publicToken)")
                // Dismiss this view controller first, then call success callback
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                        self.onSuccess(publicToken)
                    }
                }
            }
        )
        
        // Set onExit handler
        linkConfiguration.onExit = { [weak self] linkExit in
            guard let self = self else { return }
            print("⚠️ [PlaidLinkViewController] Link exited")
            // Dismiss this view controller first, then call the exit callback
            DispatchQueue.main.async {
                self.dismiss(animated: true) {
                    self.onExit()
                }
            }
        }
        
        // Create and open Link handler
        // Now 'self' is in the window hierarchy, so presentation will work
        let result = Plaid.create(linkConfiguration)
        switch result {
        case .success(let handler):
            self.linkHandler = handler
            handler.open(presentUsing: .viewController(self))
            
        case .failure(let error):
            print("❌ [PlaidLinkViewController] Failed to create Link handler: \(error)")
            self.onExit()
        }
        #else
        // LinkKit not available - show error
        print("⚠️ [PlaidLinkViewController] LinkKit not available")
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                self.onExit()
            }
        }
        #endif
    }
    
    deinit {
        #if canImport(LinkKit)
        linkHandler = nil
        #endif
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
                .foregroundColor(Color.softGraphite)
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


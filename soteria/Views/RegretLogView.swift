//
//  RegretLogView.swift
//  rever
//
//  View and manage regret purchases
//

import SwiftUI

struct RegretLogView: View {
    @EnvironmentObject var regretService: RegretLoggingService
    @State private var showLogRegret = false
    @State private var showReturnDashboard = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.98, green: 0.98, blue: 0.98)
                .ignoresSafeArea()
            
            ScrollView {
                Color.clear
                    .frame(height: 60)
                
                VStack(spacing: 24) {
                    // Summary Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Regret is a signal, not a failure")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.orange)
                                
                                Text("\(regretService.regretEntries.count) total")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("This Week")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                
                                Text("\(regretService.recentRegretCount)")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                            }
                        }
                        
                        // Pending Returns Alert
                        let pendingReturns = regretService.getReturnableRegrets()
                        if !pendingReturns.isEmpty {
                            Divider()
                            
                            HStack {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.orange)
                                
                                Text("\(pendingReturns.count) return\(pendingReturns.count == 1 ? "" : "s") pending")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                
                                Spacer()
                                
                                let approaching = regretService.getRegretsWithApproachingDeadlines().count
                                if approaching > 0 {
                                    Text("\(approaching) deadline\(approaching == 1 ? "" : "s") approaching")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        if regretService.totalRegretAmount > 0 {
                            Divider()
                            
                            HStack {
                                Text("Total Amount")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text(formatCurrency(regretService.totalRegretAmount))
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    
                    // Regret Entries
                    if regretService.regretEntries.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                            
                            Text("No Regrets Logged")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                            
                            Text("Great job! You're protecting your emotional and financial peace")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.vertical, 60)
                    } else {
                        VStack(spacing: 16) {
                            ForEach(regretService.regretEntries.sorted { $0.date > $1.date }) { regret in
                                RegretEntryCard(regret: regret)
                                    .environmentObject(regretService)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Return Dashboard Button
                    if !regretService.getReturnableRegrets().isEmpty {
                        Button(action: {
                            showReturnDashboard = true
                        }) {
                            HStack {
                                Image(systemName: "list.bullet.rectangle")
                                Text("View Return Dashboard")
                            }
                            .frame(maxWidth: .infinity)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.1, green: 0.6, blue: 0.3))
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Log Regret Button
                    Button(action: {
                        showLogRegret = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Log Regret Purchase")
                        }
                        .frame(maxWidth: .infinity)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            
            // Fixed Header
            VStack(spacing: 2) {
                Text("Regret Log")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                Color(red: 0.92, green: 0.97, blue: 0.94)
                    .ignoresSafeArea(edges: .top)
            )
            .zIndex(100)
        }
        .sheet(isPresented: $showLogRegret) {
            LogRegretPurchaseView()
                .environmentObject(regretService)
        }
        .fullScreenCover(isPresented: $showReturnDashboard) {
            NavigationView {
                ReturnDashboardView()
                    .environmentObject(regretService)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showReturnDashboard = false
                            }
                        }
                    }
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct RegretEntryCard: View {
    @EnvironmentObject var regretService: RegretLoggingService
    let regret: RegretEntry
    @State private var showDetails = false
    
    private var formattedAmount: String {
        guard let amount = regret.amount else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? ""
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: regret.date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(regret.mood.emoji)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    if let merchant = regret.merchant {
                        Text(merchant)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    if regret.amount != nil {
                        Text(formattedAmount)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Text(dateString)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let status = regret.returnStatus {
                        Text(status.displayName)
                            .font(.system(size: 12))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(status == .returned ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                            )
                            .foregroundColor(status == .returned ? .green : .orange)
                    }
                    
                    // Deadline indicator
                    if regret.returnDeadline != nil,
                       regret.returnStatus != .returned,
                       regret.returnStatus != .cannotReturn {
                        if regret.isDeadlineExpired {
                            Text("Deadline passed")
                                .font(.system(size: 10))
                                .foregroundColor(.red)
                        } else if let days = regret.daysUntilDeadline {
                            if days <= 3 {
                                Text("\(days) day\(days == 1 ? "" : "s") left")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.red)
                            } else {
                                Text("\(days) days left")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            
            Text(regret.reason)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                .lineLimit(2)
            
            if !regret.recoveryActions.isEmpty {
                HStack {
                    Text("Recovery Actions:")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    ForEach(regret.recoveryActions.prefix(2), id: \.self) { action in
                        Text(action.displayName)
                            .font(.system(size: 11))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue.opacity(0.1))
                            )
                            .foregroundColor(.blue)
                    }
                    
                    if regret.recoveryActions.count > 2 {
                        Text("+\(regret.recoveryActions.count - 2)")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .onTapGesture {
            showDetails = true
        }
        .sheet(isPresented: $showDetails) {
            RegretDetailView(regret: regret)
                .environmentObject(regretService)
        }
    }
}

struct LogRegretPurchaseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var regretService: RegretLoggingService
    
    @State private var amount: String = ""
    @State private var merchant: String = ""
    @State private var category: String = ""
    @State private var reason: String = ""
    @State private var selectedMood: MoodLevel = .neutral
    @State private var canReturn: Bool = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("Purchase Details") {
                    TextField("Amount (optional)", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    TextField("Merchant (optional)", text: $merchant)
                    
                    TextField("Category (optional)", text: $category)
                }
                
                Section("Why was this a regret?") {
                    TextField("Describe why this purchase was a regret", text: $reason, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Mood") {
                    Picker("Mood", selection: $selectedMood) {
                        ForEach(MoodLevel.allCases, id: \.self) { mood in
                            HStack {
                                Text(mood.emoji)
                                Text(mood.displayName)
                            }
                            .tag(mood)
                        }
                    }
                }
                
                Section("Return Options") {
                    Toggle("Can this be returned?", isOn: $canReturn)
                }
            }
            .navigationTitle("Log Regret")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRegret()
                    }
                    .disabled(reason.isEmpty)
                }
            }
        }
    }
    
    private func saveRegret() {
        let regret = RegretEntry(
            amount: Double(amount),
            merchant: merchant.isEmpty ? nil : merchant,
            category: category.isEmpty ? nil : category,
            reason: reason,
            mood: selectedMood,
            canReturn: canReturn
        )
        
        regretService.addRegret(regret)
        dismiss()
    }
}

struct RegretDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var regretService: RegretLoggingService
    let regret: RegretEntry
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Basic Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.system(size: 20, weight: .semibold))
                        
                        if let merchant = regret.merchant {
                            InfoRow(label: "Merchant", value: merchant)
                        }
                        
                        if let amount = regret.amount {
                            InfoRow(label: "Amount", value: formatCurrency(amount))
                        }
                        
                        if let category = regret.category {
                            InfoRow(label: "Category", value: category)
                        }
                        
                        InfoRow(label: "Mood", value: "\(regret.mood.emoji) \(regret.mood.displayName)")
                        
                        InfoRow(label: "Date", value: formatDate(regret.date))
                    }
                    
                    // Reason
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Why was this a regret?")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text(regret.reason)
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    
                    // Recovery Actions
                    if !regret.recoveryActions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recovery Actions")
                                .font(.system(size: 18, weight: .semibold))
                            
                            ForEach(regret.recoveryActions, id: \.self) { action in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(action.displayName)
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Text(action.guidance)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                                )
                            }
                        }
                    }
                    
                    // Return Deadline Alert
                    if let deadline = regret.returnDeadline,
                       regret.returnStatus != .returned,
                       regret.returnStatus != .cannotReturn {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: regret.isDeadlineExpired ? "exclamationmark.triangle.fill" : "clock.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(regret.isDeadlineExpired ? .red : (regret.isDeadlineApproaching ? .orange : Color(red: 0.1, green: 0.6, blue: 0.3)))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    if regret.isDeadlineExpired {
                                        Text("Return Deadline Passed")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.red)
                                    } else if let days = regret.daysUntilDeadline {
                                        if days <= 3 {
                                            Text("Return Deadline: \(days) day\(days == 1 ? "" : "s") left")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.orange)
                                        } else {
                                            Text("Return Deadline: \(days) days left")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                        }
                                    }
                                    
                                    Text("Deadline: \(formatDate(deadline))")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(regret.isDeadlineExpired ? Color.red.opacity(0.1) : (regret.isDeadlineApproaching ? Color.orange.opacity(0.1) : Color(red: 0.95, green: 0.98, blue: 0.95)))
                            )
                        }
                    }
                    
                    // Return Guidance
                    if let merchant = regret.merchant, let guidance = regretService.getReturnGuidance(for: merchant) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Return Support for \(merchant)")
                                .font(.system(size: 18, weight: .semibold))
                            
                            Text("We provide the maximum support permitted by law")
                                .font(.system(size: 12))
                                .italic()
                                .foregroundColor(.gray)
                                .padding(.bottom, 4)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Return Window: \(guidance.returnWindow)")
                                    .font(.system(size: 14))
                                
                                if !guidance.requirements.isEmpty {
                                    Text("Requirements:")
                                        .font(.system(size: 14, weight: .semibold))
                                    ForEach(guidance.requirements, id: \.self) { req in
                                        Text("• \(req)")
                                            .font(.system(size: 14))
                                    }
                                }
                                
                                if !guidance.steps.isEmpty {
                                    Text("Step-by-Step Instructions:")
                                        .font(.system(size: 14, weight: .semibold))
                                    ForEach(Array(guidance.steps.enumerated()), id: \.offset) { index, step in
                                        Text("\(index + 1). \(step)")
                                            .font(.system(size: 14))
                                    }
                                }
                                
                                if let contact = guidance.contactInfo {
                                    Text("Contact: \(contact)")
                                        .font(.system(size: 14))
                                }
                                
                                // Customer Service Template
                                if let template = guidance.emailTemplate {
                                    Divider()
                                        .padding(.vertical, 8)
                                    
                                    Text("Customer Service Email Template")
                                        .font(.system(size: 14, weight: .semibold))
                                    
                                    Text(template)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.gray)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                                        )
                                    
                                    Button(action: {
                                        UIPasteboard.general.string = template
                                    }) {
                                        HStack {
                                            Image(systemName: "doc.on.doc")
                                            Text("Copy Template")
                                        }
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.95, green: 0.98, blue: 0.95))
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Regret Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
        }
    }
}

#Preview {
    RegretLogView()
        .environmentObject(RegretLoggingService.shared)
}


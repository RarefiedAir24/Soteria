//
//  ReverTextField.swift
//  soteria
//
//  REVER UI KIT v1.0 - Input Field Components
//

import SwiftUI

struct ReverTextField: View {
    @Binding var text: String
    var placeholder: String
    var isFocused: Bool = false
    
    var body: some View {
        TextField(placeholder, text: $text)
            .font(.reverBody)
            .foregroundColor(.midnightSlate)
            .padding(14)
            .background(Color.dreamMist)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.reverBlue : Color.clear, lineWidth: 2)
            )
    }
}

struct ReverSecureField: View {
    @Binding var text: String
    var placeholder: String
    var isFocused: Bool = false
    
    var body: some View {
        SecureField(placeholder, text: $text)
            .font(.reverBody)
            .foregroundColor(.midnightSlate)
            .padding(14)
            .background(Color.dreamMist)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.reverBlue : Color.clear, lineWidth: 2)
            )
    }
}

struct ReverTextArea: View {
    @Binding var text: String
    var placeholder: String
    var isFocused: Bool = false
    var minHeight: CGFloat = 140
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.reverBody)
                    .foregroundColor(Color(white: 0.5))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
            }
            
            TextEditor(text: $text)
                .font(.reverBody)
                .foregroundColor(.midnightSlate)
                .padding(8)
                .frame(minHeight: minHeight)
        }
        .background(Color.cloudWhite)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isFocused ? Color.reverBlue : Color.mistGray, lineWidth: isFocused ? 2 : 1)
        )
        .cornerRadius(14)
    }
}


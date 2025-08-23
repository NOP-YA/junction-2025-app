//
//  HomeView.swift
//  JunctionBase
//
//  Created by Henry on 8/20/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextEditor(text: $vm.userPrompt)
                    .frame(minHeight: 140)
                    .padding(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        if vm.userPrompt.isEmpty {
                            Text("Type your prompt here...")
                                .foregroundColor(.secondary)
                                .padding(.top, 18)
                                .padding(.leading, 18)
                        }
                    }

                Button(action: vm.sendChatRequest) {
                    HStack {
                        if vm.isLoading { ProgressView().padding(.trailing, 8) }
                        Text(vm.isLoading ? "Sending..." : "Send")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(vm.isLoading)

                if let error = vm.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ScrollView {
                    Text(vm.responseText.isEmpty ? "Response will appear here." : vm.responseText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.secondary.opacity(0.08))
                        .cornerRadius(10)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Chat (Moya)")
        }
    }
}

#Preview {
    HomeView()
}


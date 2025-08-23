//
//  HomeViewModel.swift
//  JunctionBase
//
//  Created by Henry on 8/23/25.
//

import Foundation
import Combine
import Moya

final class HomeViewModel: ObservableObject {
    @Published var userPrompt: String = ""
    @Published var responseText: String = ""
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let provider: MoyaProvider<OpenAIService>

    init() {
        // Network logger for debugging. Remove or lower verbosity in production.
        let logger = NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))
        let apiKeyPlugin = APIKeyPlugin { Secrets.azureOpenAIKey }

        self.provider = MoyaProvider<OpenAIService>(
            plugins: [apiKeyPlugin, logger]
        )
    }

    func sendChatRequest() {
        let trimmed = userPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            self.errorMessage = "Please enter a prompt."
            return
        }

        isLoading = true
        errorMessage = nil
        responseText = ""

        let messages = [
            ChatMessage(role: "system", content: "You are a helpful assistant."),
            ChatMessage(role: "user", content: trimmed)
        ]

        let body = ChatRequest(
            messages: messages,
            max_tokens: 4096,
            temperature: 1.0,
            top_p: 1.0,
            model: "gpt-4o"
        )

        provider.request(.chat(request: body)) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                switch result {
                case .success(let response):
                    do {
                        let decoded = try JSONDecoder().decode(ChatResponse.self, from: response.data)
                        if let text = decoded.choices.first?.message.content, !text.isEmpty {
                            self.responseText = text
                        } else {
                            self.errorMessage = "No response content found."
                        }
                    } catch {
                        self.errorMessage = "Decoding failed: \(error.localizedDescription)"
                    }

                case .failure(let error):
                    self.errorMessage = "Request failed: \(error.localizedDescription)"
                }
            }
        }
    }
}


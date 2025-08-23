//
//  AzureService.swift
//  JunctionBase
//
//  Created by Henry on 8/23/25.
//

import Foundation
import Moya

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatRequest: Codable {
    let messages: [ChatMessage]
    let max_tokens: Int
    let temperature: Double
    let top_p: Double
    let model: String
}

struct ChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

enum OpenAIService {
    case chat(request: ChatRequest)
}

extension OpenAIService: TargetType {
    var baseURL: URL {
        URL(string: "https://alphamales.openai.azure.com")!
    }

    var path: String {
        // ⚠️ 반드시 실제 "배포 이름"으로 수정해야 함 (Azure Portal에서 확인)
        "/openai/deployments/gpt-4o/chat/completions"
    }

    var method: Moya.Method { .post }

    var task: Task {
        switch self {
        case .chat(let request):
            // api-version 은 쿼리 파라미터로 추가
            let params: [String: Any] = ["api-version": "2024-12-01-preview"]
            return .requestCompositeParameters(
                bodyParameters: request.asDictionary(),
                bodyEncoding: JSONEncoding.default,
                urlParameters: params
            )
        }
    }

    var headers: [String : String]? {
        [
            "Content-Type": "application/json"
            // api-key is injected by APIKeyPlugin
        ]
    }

    var sampleData: Data { Data() }
}

// MARK: - Secrets
enum Secrets {
    static var azureOpenAIKey: String {
        // 환경변수 이름은 AZURE_OPENAI_KEY
        ProcessInfo.processInfo.environment["AZURE_OPENAI_KEY"] ?? ""
    }
}

// MARK: - Plugin
final class APIKeyPlugin: PluginType {
    private let keyProvider: () -> String
    init(keyProvider: @escaping () -> String) { self.keyProvider = keyProvider }

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var req = request
        let key = keyProvider()
        if !key.isEmpty {
            req.setValue(key, forHTTPHeaderField: "api-key")
        }
        return req
    }
}

// MARK: - Helper
private extension Encodable {
    func asDictionary() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }
}

// MARK: - Provider Factory (optional reuse)
func makeOpenAIProvider() -> MoyaProvider<OpenAIService> {
    let logger = NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))
    let keyPlugin = APIKeyPlugin { Secrets.azureOpenAIKey }
    return MoyaProvider<OpenAIService>(plugins: [keyPlugin, logger])
}

// MARK: - AzureAIService Wrapper
final class AzureAIService {
    private let provider: MoyaProvider<OpenAIService>

    init() {
        self.provider = makeOpenAIProvider()
    }

    /// Sends a simple chat request using the current deployment
    /// - Parameters:
    ///   - userPrompt: user's input
    ///   - maxTokens: default 4096
    ///   - temperature: default 1.0
    ///   - topP: default 1.0
    ///   - model: kept for compatibility with current `ChatRequest`
    ///   - completion: returns content string or error
    public func sendChat(userPrompt: String,
                         maxTokens: Int = 4096,
                         temperature: Double = 1.0,
                         topP: Double = 1.0,
                         model: String = "gpt-4o",
                         completion: @escaping (Result<String, Error>) -> Void) {

        let messages = [
            ChatMessage(role: "system", content: "You are a helpful assistant."),
            ChatMessage(role: "user", content: userPrompt)
        ]
        let body = ChatRequest(
            messages: messages,
            max_tokens: maxTokens,
            temperature: temperature,
            top_p: topP,
            model: model
        )

        provider.request(.chat(request: body)) { result in
            switch result {
            case .success(let response):
                do {
                    let decoded = try JSONDecoder().decode(ChatResponse.self, from: response.data)
                    if let text = decoded.choices.first?.message.content, !text.isEmpty {
                        completion(.success(text))
                    } else {
                        completion(.failure(NSError(domain: "AzureAIService",
                                                    code: -1,
                                                    userInfo: [NSLocalizedDescriptionKey: "No response content found"])) )
                    }
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

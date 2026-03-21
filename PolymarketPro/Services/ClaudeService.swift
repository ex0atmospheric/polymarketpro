import Foundation

struct ChatMessage: Identifiable {
    let id: UUID
    let role: String   // "user" or "assistant"
    let content: String
    let timestamp: Date

    init(role: String, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

@MainActor
class ClaudeService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isThinking = false

    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-sonnet-4-6"
    private let systemPrompt = "You are a quantitative analyst specializing in prediction markets. Help users analyze Polymarket markets, probabilities, and trading strategies."

    private var apiKey: String {
        UserDefaults.standard.string(forKey: "anthropic_api_key") ?? ""
    }

    func send(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard !apiKey.isEmpty else {
            messages.append(ChatMessage(role: "assistant", content: "Please add your Anthropic API key in Settings before chatting."))
            return
        }

        messages.append(ChatMessage(role: "user", content: text))
        isThinking = true
        defer { isThinking = false }

        // Build message history for API (only user/assistant roles)
        let apiMessages = messages.map { msg -> [String: String] in
            ["role": msg.role == "user" ? "user" : "assistant",
             "content": msg.content]
        }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": systemPrompt,
            "messages": apiMessages
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            messages.append(ChatMessage(role: "assistant", content: "Failed to serialize request."))
            return
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = json["content"] as? [[String: Any]],
               let firstBlock = content.first,
               let text = firstBlock["text"] as? String {
                messages.append(ChatMessage(role: "assistant", content: text))
            } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let errObj = json["error"] as? [String: Any],
                      let errMsg = errObj["message"] as? String {
                messages.append(ChatMessage(role: "assistant", content: "API Error: \(errMsg)"))
            } else {
                messages.append(ChatMessage(role: "assistant", content: "Unexpected response from API."))
            }
        } catch {
            messages.append(ChatMessage(role: "assistant", content: "Network error: \(error.localizedDescription)"))
        }
    }
}

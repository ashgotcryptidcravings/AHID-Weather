import Foundation

actor AIService {
    private var anthropicKey: String?
    private var geminiKey: String?
    private var openaiKey: String?

    func setKeys(anthropic: String?, gemini: String?, openai: String?) {
        self.anthropicKey = anthropic
        self.geminiKey = gemini
        self.openaiKey = openai
    }

    var hasAnyKey: Bool {
        !(anthropicKey ?? "").isEmpty || !(geminiKey ?? "").isEmpty || !(openaiKey ?? "").isEmpty
    }

    func chat(system: String, message: String) async -> String? {
        // Try providers in order: Anthropic -> Gemini -> OpenAI
        if let key = anthropicKey, !key.isEmpty {
            if let result = await anthropicCall(system: system, message: message, key: key) {
                return result
            }
        }
        if let key = geminiKey, !key.isEmpty {
            if let result = await geminiCall(system: system, message: message, key: key) {
                return result
            }
        }
        if let key = openaiKey, !key.isEmpty {
            if let result = await openaiCall(system: system, message: message, key: key) {
                return result
            }
        }
        return nil
    }

    private func anthropicCall(system: String, message: String, key: String) async -> String? {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-3-5-haiku-latest",
            "max_tokens": 300,
            "system": system,
            "messages": [["role": "user", "content": message]]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = json["content"] as? [[String: Any]] {
                return content.compactMap { $0["text"] as? String }.joined()
            }
        } catch {
            print("[AHID AI] Anthropic error: \(error.localizedDescription)")
        }
        return nil
    }

    private func geminiCall(system: String, message: String, key: String) async -> String? {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(key)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "system_instruction": ["parts": [["text": system]]],
            "contents": [["parts": [["text": message]]]],
            "generationConfig": ["maxOutputTokens": 300]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let content = candidates.first?["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]] {
                return parts.first?["text"] as? String
            }
        } catch {
            print("[AHID AI] Gemini error: \(error.localizedDescription)")
        }
        return nil
    }

    private func openaiCall(system: String, message: String, key: String) async -> String? {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "max_tokens": 300,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": message]
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let msg = choices.first?["message"] as? [String: Any] {
                return msg["content"] as? String
            }
        } catch {
            print("[AHID AI] OpenAI error: \(error.localizedDescription)")
        }
        return nil
    }
}

import Foundation

actor AIService {
    private var anthropicKey: String?
    private var geminiKey: String?
    private var openaiKey: String?

    func setKeys(anthropic: String?, gemini: String?, openai: String?) {
        self.anthropicKey = anthropic
        self.geminiKey    = gemini
        self.openaiKey    = openai
    }

    var hasAnyKey: Bool {
        !(anthropicKey ?? "").isEmpty || !(geminiKey ?? "").isEmpty || !(openaiKey ?? "").isEmpty
    }

    // MARK: - Chat

    func chat(system: String, message: String) async -> String? {
        if let key = anthropicKey, !key.isEmpty {
            if let result = await anthropicCall(system: system, message: message, key: key) { return result }
        }
        if let key = geminiKey, !key.isEmpty {
            if let result = await geminiCall(system: system, message: message, key: key) { return result }
        }
        if let key = openaiKey, !key.isEmpty {
            if let result = await openaiCall(system: system, message: message, key: key) { return result }
        }
        return nil
    }

    // MARK: - Key Testing

    /// Returns (success, message) where message is a human-readable status.
    func testKey(provider: AIProvider, key: String) async -> (Bool, String) {
        switch provider {
        case .anthropic: return await testAnthropic(key: key)
        case .gemini:    return await testGemini(key: key)
        case .openai:    return await testOpenAI(key: key)
        case .owm:       return await testOWM(key: key)
        }
    }

    private func testAnthropic(key: String) async -> (Bool, String) {
        // GET /v1/models — no body required, returns 200 for valid keys
        guard let url = URL(string: "https://api.anthropic.com/v1/models") else {
            return (false, AppError.key003_networkError("Bad URL").localizedDescription ?? "")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 8
        req.setValue(key,          forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        return await performKeyTest(request: req, provider: "Anthropic")
    }

    private func testGemini(key: String) async -> (Bool, String) {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(key)") else {
            return (false, AppError.key003_networkError("Bad URL").localizedDescription ?? "")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 8
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["contents": [["parts": [["text": "Hi"]]]]]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return await performKeyTest(request: req, provider: "Gemini")
    }

    private func testOpenAI(key: String) async -> (Bool, String) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            return (false, AppError.key003_networkError("Bad URL").localizedDescription ?? "")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 8
        req.setValue("application/json",   forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(key)",      forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "max_tokens": 10,
            "messages": [["role": "user", "content": "Hi"]]
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return await performKeyTest(request: req, provider: "OpenAI")
    }

    private func testOWM(key: String) async -> (Bool, String) {
        let urlStr = "https://api.openweathermap.org/data/2.5/weather?lat=41.6&lon=-83.5&appid=\(key)"
        guard let url = URL(string: urlStr) else {
            return (false, AppError.key003_networkError("Bad URL").localizedDescription ?? "")
        }
        var req = URLRequest(url: url)
        req.timeoutInterval = 8
        return await performKeyTest(request: req, provider: "OpenWeatherMap")
    }

    private func performKeyTest(request: URLRequest, provider: String) async -> (Bool, String) {
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return (false, AppError.key003_networkError("No HTTP response").localizedDescription ?? "")
            }
            switch http.statusCode {
            case 200, 201:
                return (true, "\(provider) key valid ✓")
            case 401, 403:
                return (false, AppError.key001_invalidKey(provider).localizedDescription ?? "")
            case 402:
                return (true, "\(provider) key valid — account has no credits.")
            case 429:
                return (true, AppError.key002_rateLimited(provider).localizedDescription ?? "")
            case 400:
                return (false, "[\(AppError.key004_httpError(400, provider).code)] \(provider) rejected the request (400). Try again.")
            case 500, 503:
                return (true, "\(provider) server error (\(http.statusCode)) — key is likely valid.")
            case 529:
                return (true, "\(provider) overloaded (529) — key valid, service busy.")
            default:
                return (false, AppError.key004_httpError(http.statusCode, provider).localizedDescription ?? "")
            }
        } catch let e as URLError where e.code == .timedOut {
            return (false, AppError.key003_networkError("Timed out").localizedDescription ?? "")
        } catch {
            return (false, AppError.key003_networkError(error.localizedDescription).localizedDescription ?? "")
        }
    }

    // MARK: - Provider Calls

    private func anthropicCall(system: String, message: String, key: String) async -> String? {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key,                forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01",       forHTTPHeaderField: "anthropic-version")
        let body: [String: Any] = [
            "model": "claude-3-5-haiku-latest",
            "max_tokens": 300,
            "system": system,
            "messages": [["role": "user", "content": message]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = json["content"] as? [[String: Any]] {
                return content.compactMap { $0["text"] as? String }.joined()
            }
        } catch { print("[AHID AI] Anthropic: \(error.localizedDescription)") }
        return nil
    }

    private func geminiCall(system: String, message: String, key: String) async -> String? {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(key)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "system_instruction": ["parts": [["text": system]]],
            "contents": [["parts": [["text": message]]]],
            "generationConfig": ["maxOutputTokens": 300]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let content = candidates.first?["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]] {
                return parts.first?["text"] as? String
            }
        } catch { print("[AHID AI] Gemini: \(error.localizedDescription)") }
        return nil
    }

    private func openaiCall(system: String, message: String, key: String) async -> String? {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)",    forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "max_tokens": 300,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user",   "content": message]
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let msg = choices.first?["message"] as? [String: Any] {
                return msg["content"] as? String
            }
        } catch { print("[AHID AI] OpenAI: \(error.localizedDescription)") }
        return nil
    }
}

// MARK: - AI Provider
enum AIProvider: String, CaseIterable, Identifiable {
    case anthropic = "Anthropic"
    case gemini    = "Gemini"
    case openai    = "OpenAI"
    case owm       = "OpenWeatherMap"

    var id: String { rawValue }
}

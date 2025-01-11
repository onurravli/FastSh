import Foundation

struct Message: Codable {
    let role: String
    let content: String
}

struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Float
}

struct ChatCompletionResponse: Codable {
    struct Choice: Codable {
        let message: Message
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }
    
    let id: String
    let choices: [Choice]
}

enum OpenAIError: LocalizedError {
    case invalidURL
    case invalidAPIKey
    case networkError(Error)
    case invalidResponse
    case apiError(Int, String)
    case decodingError(Error)
    case noInternetConnection
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidAPIKey:
            return "Invalid or missing API key. Please check your settings."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .noInternetConnection:
            return "No internet connection available. Please check your network settings."
        }
    }
}

class OpenAIService {
    private let session: URLSession
    private let maxRetries = 3
    
    init() {
        print("Initializing OpenAI Service...")
        
        // Create URL session configuration with timeout and better settings
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil // Disable caching for API requests
        self.session = URLSession(configuration: config)
    }
    
    func sendChatCompletion(systemMessage: String, userMessage: String) async throws -> String {
        var retryCount = 0
        var lastError: Error?
        
        while retryCount < maxRetries {
            do {
                return try await sendChatCompletionWithoutRetry(systemMessage: systemMessage, userMessage: userMessage)
            } catch let error as URLError where error.code == .timedOut || error.code == .networkConnectionLost {
                lastError = error
                retryCount += 1
                if retryCount < maxRetries {
                    print("Request failed (attempt \(retryCount)/\(maxRetries)). Retrying in \(pow(2.0, Double(retryCount))) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000))
                    continue
                }
            } catch {
                throw error
            }
        }
        
        throw OpenAIError.networkError(lastError ?? URLError(.unknown))
    }
    
    private func sendChatCompletionWithoutRetry(systemMessage: String, userMessage: String) async throws -> String {
        print("\n--- Starting OpenAI API Request ---")
        
        guard let apiKey = Settings.shared.apiKey, !apiKey.isEmpty else {
            throw OpenAIError.invalidAPIKey
        }
        
        let baseURL = Settings.shared.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        print("Base URL: \(baseURL)")
        print("System message length: \(systemMessage.count)")
        print("User message length: \(userMessage.count)")
        
        // Validate URL with more detailed error handling
        guard let url = URL(string: baseURL) else {
            print("Error: Invalid URL format for \(baseURL)")
            throw OpenAIError.invalidURL
        }
        
        guard url.scheme == "https" else {
            print("Error: URL must use HTTPS")
            throw OpenAIError.invalidURL
        }
        
        let messages = [
            Message(role: "system", content: systemMessage),
            Message(role: "user", content: userMessage)
        ]
        
        let request = ChatCompletionRequest(
            model: "gpt-4-1106-preview",
            messages: messages,
            temperature: 0.7
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 30
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
            print("Request body prepared (size: \(jsonData.count) bytes)")
            print("Making API request to host: \(url.host ?? "unknown")")
            
            let (data, response) = try await session.data(for: urlRequest)
            print("Received response (size: \(data.count) bytes)")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Error: Response is not HTTPURLResponse")
                throw OpenAIError.invalidResponse
            }
            
            print("Response status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 401 {
                print("API Error: Unauthorized - Invalid API key")
                throw OpenAIError.invalidAPIKey
            }
            
            if httpResponse.statusCode != 200 {
                let responseString = String(data: data, encoding: .utf8) ?? "No response body"
                print("API Error Response: \(responseString)")
                throw OpenAIError.apiError(httpResponse.statusCode, responseString)
            }
            
            do {
                let completionResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
                guard let result = completionResponse.choices.first?.message.content else {
                    print("Error: No message content in response")
                    throw OpenAIError.invalidResponse
                }
                print("Successfully decoded response (result length: \(result.count))")
                print("--- Completed OpenAI API Request ---\n")
                return result
            } catch {
                print("Failed to decode response: \(error)")
                print("Raw response: \(String(data: data, encoding: .utf8) ?? "Unable to read response data")")
                throw OpenAIError.decodingError(error)
            }
        } catch let error as OpenAIError {
            print("OpenAI Error: \(error.localizedDescription)")
            throw error
        } catch let error as URLError {
            print("URL Error: \(error.localizedDescription)")
            print("Error code: \(error.code.rawValue)")
            
            switch error.code {
            case .notConnectedToInternet:
                throw OpenAIError.noInternetConnection
            case .timedOut:
                print("Request timed out")
                throw error // Let the retry logic handle timeouts
            case .cannotFindHost, .cannotConnectToHost:
                print("Cannot connect to host: \(error.failingURL?.host ?? "unknown")")
                throw OpenAIError.networkError(error)
            default:
                throw OpenAIError.networkError(error)
            }
        } catch {
            print("Unexpected error: \(error.localizedDescription)")
            throw OpenAIError.networkError(error)
        }
    }
} 
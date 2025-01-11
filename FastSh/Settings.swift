import Foundation

class Settings: ObservableObject {
    static let shared = Settings()
    
    private let defaults = UserDefaults.standard
    private let apiKeyKey = "openai_api_key"
    private let baseURLKey = "openai_base_url"
    
    @Published var apiKey: String? {
        didSet {
            defaults.set(apiKey, forKey: apiKeyKey)
        }
    }
    
    @Published var baseURL: String {
        didSet {
            defaults.set(baseURL, forKey: baseURLKey)
        }
    }
    
    private init() {
        self.apiKey = defaults.string(forKey: apiKeyKey)
        self.baseURL = defaults.string(forKey: baseURLKey) ?? "https://api.openai.com/v1/chat/completions"
    }
} 
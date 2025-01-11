import Foundation

enum EnvironmentError: LocalizedError {
    case envFileNotFound
    case envFileLoadError(String)
    
    var errorDescription: String? {
        switch self {
        case .envFileNotFound:
            return "Could not find .env file in any location"
        case .envFileLoadError(let path):
            return "Failed to load .env file from \(path)"
        }
    }
}

enum EnvLoader {
    private static var variables: [String: String] = [:]
    
    static func load() throws {
        print("Starting environment loading process...")
        let bundlePath = Bundle.main.bundlePath
        print("Bundle path: \(bundlePath)")
        
        // First try to load from bundle's Resources directory
        let resourcePath = bundlePath + "/Contents/Resources/.env"
        print("Attempting to load from resource path: \(resourcePath)")
        if loadFromPath(resourcePath) {
            print("Successfully loaded .env from bundle resources")
            return
        }
        
        print("Could not find .env file in bundle Resources directory")
        
        // Fallback to development path
        if let projectPath = Bundle.main.resourcePath?
            .components(separatedBy: "DerivedData")[0]
            .trimmingCharacters(in: .whitespacesAndNewlines) {
            print("Trying development path: \(projectPath)")
            let envPath = projectPath + "/FastSh/Resources/.env"
            if loadFromPath(envPath) {
                print("Successfully loaded .env from development path")
                return
            }
            throw EnvironmentError.envFileLoadError(envPath)
        }
        
        throw EnvironmentError.envFileNotFound
    }
    
    private static func loadFromPath(_ path: String) -> Bool {
        print("Attempting to load .env from path: \(path)")
        do {
            let contents = try String(contentsOfFile: path, encoding: .utf8)
            print("Successfully read .env file contents")
            let lines = contents.components(separatedBy: .newlines)
            
            for line in lines {
                let parts = line.components(separatedBy: "=")
                if parts.count == 2 {
                    let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    variables[key] = value
                    print("Loaded environment variable: \(key)")
                }
            }
            
            // Print all loaded variables (without values for security)
            print("All loaded environment variables: \(Array(variables.keys))")
            return true
        } catch {
            print("Error loading .env file from \(path): \(error)")
            return false
        }
    }
    
    static func get(_ key: String) -> String? {
        let value = variables[key]
        print("Retrieving environment variable \(key): \(value != nil ? "found" : "not found")")
        return value
    }
    
    static var openAIApiKey: String? {
        return get("OPENAI_API_KEY")
    }
} 
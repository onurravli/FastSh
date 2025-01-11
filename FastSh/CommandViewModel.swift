import Foundation
import SwiftUI

@MainActor
class CommandViewModel: ObservableObject {
    private var openAIService: OpenAIService
    @Published var isLoading = false
    @Published var error: String?
    @Published var suggestedCommand: String?
    
    private let systemMessage = "You are a helpful AI bot to write shell commands with users requirements. Just write required shell command, don't write something else. Don't use markdown or any other formatting. Just write the command."
    
    init() {
        self.openAIService = OpenAIService()
    }
    
    func processCommand(_ command: String) async {
        isLoading = true
        error = nil
        suggestedCommand = nil
        
        do {
            let response = try await openAIService.sendChatCompletion(
                systemMessage: systemMessage,
                userMessage: command
            )
            suggestedCommand = response.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
} 
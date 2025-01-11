import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = Settings.shared
    @State private var isApiKeyVisible = false
    
    var body: some View {
        Form {
            Section {
                HStack {
                    if isApiKeyVisible {
                        TextField("OpenAI API Key", text: Binding(
                            get: { settings.apiKey ?? "" },
                            set: { settings.apiKey = $0 }
                        ))
                    } else {
                        SecureField("OpenAI API Key", text: Binding(
                            get: { settings.apiKey ?? "" },
                            set: { settings.apiKey = $0 }
                        ))
                    }
                    
                    Button(action: {
                        isApiKeyVisible.toggle()
                    }) {
                        Image(systemName: isApiKeyVisible ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                TextField("Base URL", text: Binding(
                    get: { settings.baseURL },
                    set: { settings.baseURL = $0 }
                ))
                .textFieldStyle(.roundedBorder)
            } header: {
                Text("OpenAI Configuration")
            } footer: {
                Text("Your API key is stored securely in the keychain and never shared.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

#Preview {
    SettingsView()
} 
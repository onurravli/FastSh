//
//  ContentView.swift
//  FastSh
//
//  Created by Onur Ravli on 11.01.2025.
//

import SwiftUI
import AppKit

struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            callback(view.window)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class NotificationWindowController {
    private var window: NSWindow?
    private var parentWindow: NSWindow?
    private static let shared = NotificationWindowController()
    
    static func showNotification(_ message: String, below window: NSWindow?) {
        DispatchQueue.main.async {
            shared.parentWindow = window
            shared.display(message)
        }
    }
    
    private func display(_ message: String) {
        if window == nil {
            let view = NotificationView(message: message)
            let hostingView = NSHostingView(rootView: view)
            
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 200, height: 40),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            window?.backgroundColor = .clear
            window?.isOpaque = false
            window?.hasShadow = true
            window?.level = parentWindow?.level ?? .statusBar
            window?.isReleasedWhenClosed = false
            window?.contentView = hostingView
        }
        
        if let parentWindow = parentWindow {
            let parentFrame = parentWindow.frame
            let notificationFrame = window?.frame ?? .zero
            
            // Position the notification window below the parent window
            let x = parentFrame.minX + (parentFrame.width - notificationFrame.width) / 2
            let y = parentFrame.minY - notificationFrame.height - 8 // 8px gap
            
            window?.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        window?.orderFront(nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.window?.orderOut(nil)
        }
    }
}

struct NotificationView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(message)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = CommandViewModel()
    @State private var command: String = ""
    @FocusState private var isFocused: Bool
    @State private var window: NSWindow?
    
    var body: some View {
        HStack {
            Image(systemName: "terminal")
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            TextField("Enter your command...", text: $command)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .font(.system(size: 14))
                .onSubmit {
                    Task {
                        await viewModel.processCommand(command)
                        if let suggestedCommand = viewModel.suggestedCommand {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(suggestedCommand, forType: .string)
                            NotificationWindowController.showNotification("Command Copied", below: window)
                            command = ""
                            
                            // Close the prompt window
                            window?.orderOut(nil)
                            NSApp.hide(nil)
                        }
                    }
                }
                .disabled(viewModel.isLoading)
            
            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .padding(.trailing, 4)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.windowBackgroundColor).opacity(0.95))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 2)
        }
        .frame(height: 60)
        .background(WindowAccessor { window in
            self.window = window
        })
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
        .onChange(of: isFocused) { oldValue, newValue in
            if !newValue {
                DispatchQueue.main.async {
                    isFocused = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 600, height: 60)
        .padding()
}

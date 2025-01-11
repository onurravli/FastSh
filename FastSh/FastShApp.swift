//
//  FastShApp.swift
//  FastSh
//
//  Created by Onur Ravli on 11.01.2025.
//

import SwiftUI
import Combine
import AppKit
import Carbon
import os
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var hotKey: HotKey?
    private let logger = Logger(subsystem: "com.innoversat.FastSh", category: "AppDelegate")
    private var window: NSWindow?
    private var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("FastSh app launched")
        logger.info("App did finish launching")
        
        // Set up notifications
        UNUserNotificationCenter.current().delegate = self
        
        // Set up the window
        let contentView = ContentView()
        let hostingView = NSHostingView(rootView: contentView)
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 60),
            styleMask: [.borderless, .titled],
            backing: .buffered,
            defer: false
        )
        
        window?.backgroundColor = .clear
        window?.isOpaque = false
        window?.hasShadow = true
        window?.center()
        window?.contentView = hostingView
        window?.level = .floating
        window?.collectionBehavior = [.canJoinAllSpaces, .transient]
        window?.isReleasedWhenClosed = false
        window?.identifier = NSUserInterfaceItemIdentifier("command-input")
        window?.titlebarAppearsTransparent = true
        window?.titleVisibility = .hidden
        window?.standardWindowButton(.closeButton)?.isHidden = true
        window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window?.standardWindowButton(.zoomButton)?.isHidden = true
        
        // Register hotkey
        hotKey = HotKey(key: .space, modifiers: [.option]) { [weak self] in
            self?.toggleMainWindow()
        }
        
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
    }
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    func showSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingView = NSHostingView(rootView: settingsView)
            
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            
            settingsWindow?.title = "Settings"
            settingsWindow?.contentView = hostingView
            settingsWindow?.center()
            settingsWindow?.isReleasedWhenClosed = false
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func toggleMainWindow() {
        logger.info("Attempting to toggle window")
        guard let window = self.window else {
            logger.error("Window not initialized")
            return
        }
        
        if window.isVisible {
            window.orderOut(nil)
            NSApp.hide(nil)
        } else {
            window.center()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            
            // Focus the window after a brief delay to ensure it's ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                window.makeKey()
            }
        }
    }
}

class HotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let callback: () -> Void
    
    init(key: Key, modifiers: NSEvent.ModifierFlags, callback: @escaping () -> Void) {
        self.callback = callback
        register(key: key, modifiers: modifiers)
    }
    
    private func register(key: Key, modifiers: NSEvent.ModifierFlags) {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType("FAST".utf8.reduce(0) { ($0 << 8) + OSType($1) })
        hotKeyID.id = 1
        
        let modifierFlags = carbonFlags(from: modifiers)
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), 
                                    eventKind: UInt32(kEventHotKeyPressed))
        
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())
        
        let handlerCallback: EventHandlerUPP = { _, eventRef, userData in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let hotKey = Unmanaged<HotKey>.fromOpaque(userData).takeUnretainedValue()
            hotKey.callback()
            return OSStatus(noErr)
        }
        
        InstallEventHandler(GetApplicationEventTarget(),
                          handlerCallback,
                          1,
                          &eventType,
                          selfPtr,
                          &eventHandler)
        
        RegisterEventHotKey(UInt32(key.rawValue),
                          UInt32(modifierFlags),
                          hotKeyID,
                          GetApplicationEventTarget(),
                          0,
                          &hotKeyRef)
    }
    
    private func carbonFlags(from cocoaFlags: NSEvent.ModifierFlags) -> Int {
        var carbonFlags = 0
        if cocoaFlags.contains(.option) { carbonFlags |= optionKey }
        return carbonFlags
    }
    
    enum Key: Int {
        case space = 49
    }
    
    deinit {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}

@main
struct FastShApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("FastSh", systemImage: "terminal") {
            Button("Show Command Input (⌥ Space)") {
                appDelegate.toggleMainWindow()
            }
            Divider()
            Button("Settings...") {
                appDelegate.showSettings()
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        
        WindowGroup {
            EmptyView()
        }
    }
}

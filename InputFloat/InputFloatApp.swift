//
//  InputFloatApp.swift
//  InputFloat
//

import SwiftUI

@main
struct InputFloatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var config = FloatWindowConfig.shared
    
    @StateObject private var monitor = InputMethodMonitor()
    var body: some Scene {
        Settings {
            SettingsView(config: config, monitor: monitor)
        }
        
        MenuBarExtra("InputFloat", systemImage: "keyboard") {
            MenuBarView()
        }
    }
}

struct MenuBarView: View {
    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        
        SettingsLink {
            Text("设置...")
        }
        .keyboardShortcut(",", modifiers: .command)
        
        Divider()
        
        Button("退出") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var floatingWindowController: FloatingWindowController?
    private var monitor: InputMethodMonitor?
    private var config = FloatWindowConfig.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        monitor = InputMethodMonitor()
        
        if let monitor = monitor {
            floatingWindowController = FloatingWindowController(monitor: monitor, config: config)
            floatingWindowController?.show()
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showFloatingWindow),
            name: NSNotification.Name("ShowFloatingWindow"),
            object: nil
        )
        
         NSApp.setActivationPolicy(.accessory)
    }
    
    @objc private func showFloatingWindow() {
        floatingWindowController?.show()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

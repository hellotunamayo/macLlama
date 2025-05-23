//
//  OllamaUIAppApp.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/7/25.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false //This causes the app not to quit when the last window is closed.
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        let preferences = UserDefaults.standard
        
        if let quitServerOnAppQuit = preferences.dictionary(forKey: "serverKillWithApp") {
            UserDefaults.standard.set(quitServerOnAppQuit, forKey: "serverKillWithApp")
        }
        
        if preferences.bool(forKey: "serverKillWithApp") {
            ShellService.killOllama()
        }
        
        print("✅ applicationWillTerminate triggered")
    }
}

@main
struct macLlamaApp: App {
    @Environment(\.scenePhase) var scenePhase
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject var serverStatus: ServerStatus = .init()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ConversationView()
                    .navigationTitle("macLlama")
            }
            .environmentObject(serverStatus)
            .frame(minWidth: Units.appFrameMinWidth, idealWidth: Units.appFrameMinWidth,
                   minHeight: Units.appFrameMinHeight, idealHeight: Units.appFrameMinHeight)
        }
        .commands {
            CommandMenu("Utility") {
                HStack {
                    Text("Ollama server is \(serverStatus.indicator ? "on" : "off")")
                        .foregroundStyle(serverStatus.indicator ? .green : .red)
                }
                .task {
                    try? await serverStatus.updateServerStatus()
                }
                
                Divider()
                
                Button {
                    Task {
                        let _ = try await ShellService.runShellScript(ShellCommand.startServer.rawValue)
                    }
                } label: {
                    Text("Start Ollama Server")
                }
                
                Button {
                    Task {
                        try await ShellService.openTerminal()
                    }
                } label: {
                    Text("Open Terminal.app")
                }
            }
            
            CommandGroup(after: .help) {
                Link("Search models from Ollama.com", destination: URL(string: "https://ollama.com/search")!)
            }
            
            CommandGroup(after: .help) {
                Link("Check for updates", destination: URL(string: "https://github.com/hellotunamayo/macLlama/releases")!)
            }
        }
        
        MenuBarExtra("macLlama", image: "macLlama-menuIcon") {
            MenuBarExtraView()
                .environmentObject(serverStatus)
                .onChange(of: scenePhase) { _, newValue in
                    if newValue == .active {
                        Task {
                            try? await serverStatus.updateServerStatus()
                        }
                    }
                }
        }
        
        Settings {
            PreferencePaneView()
        }
    }
}

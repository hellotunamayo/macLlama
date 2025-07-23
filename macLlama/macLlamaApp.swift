//
//  OllamaUIAppApp.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/7/25.
//

import SwiftUI
import SwiftData
import MarkdownUI

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
    @AppStorage("lastUpdateCheckDate") var lastUpdateCheckDate: Double = AppSettings.lastUpdateCheckDate
    @AppStorage("isAutoUpdateEnabled") var isAutoUpdateEnabled: Bool = AppSettings.isAutoUpdateEnabled
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.openWindow) var openWindow
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject var serverStatus: ServerStatus = .init()
    @State private var updateData: (version: String, htmlURL: String, body: String) = ("","","")
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ConversationView()
                    .navigationTitle("macLlama")
            }
            .environmentObject(serverStatus)
            .frame(minWidth: Units.appFrameMinWidth, idealWidth: Units.appFrameMinWidth,
                   minHeight: Units.appFrameMinHeight, idealHeight: Units.appFrameMinHeight)
            .task {
                //auto check for updates
                let intervalSinceLastCheck: TimeInterval = Date().timeIntervalSince1970 - TimeInterval(lastUpdateCheckDate)
                if isAutoUpdateEnabled && intervalSinceLastCheck > 60 * 60 * 24 { //Check update every 1 day
                    do {
                        let githubService = GithubService()
                        guard let checkVersionResult = try await githubService.checkForUpdates() else { return }
                        self.updateData = checkVersionResult
                        openWindow(id: "updateWindow")
                        self.lastUpdateCheckDate = Date().timeIntervalSince1970
                        
                        #if DEBUG
                        debugPrint("updated checked in : \(lastUpdateCheckDate)")
                        #endif
                    } catch {
                        
                    }
                }
            }
        }
        .modelContainer(for: SwiftDataChatHistory.self)
        .commands {
            CommandMenu("Utility") {
                HStack {
                    Text("Ollama server is \(serverStatus.isOnline ? "on" : "off")")
                        .foregroundStyle(serverStatus.isOnline ? .green : .red)
                }
                .task {
                    try? await serverStatus.updateServerStatus()
                }
                
                Divider()
                
                Button {
                    Task {
                        let startCommand = ShellCommand.startServer.rawValue
                        if let _ = try await ShellService.runShellScript(startCommand) {
                            
                            try? await Task.sleep(for: .seconds(1))
                            try? await serverStatus.updateServerStatus()
                            
                            #if DEBUG
                            debugPrint(serverStatus)
                            #endif
                        }
                    }
                } label: {
                    Text("Start Local Ollama Server")
                }
                
                Button {
                    Task {
                        try await ShellService.openTerminal()
                    }
                } label: {
                    Text("Open Terminal.app")
                }
                
                Divider()
                
                Button("Stop Local Ollama server", role: .destructive) {
                    Task {
                        let _ = ShellService.killOllama()
                        try await Task.sleep(for: .seconds(1))
                        try? await serverStatus.updateServerStatus()
                    }
                }
            }
            
            CommandGroup(after: .help) {
                Link("Search models from Ollama.com", destination: URL(string: "https://ollama.com/search")!)
                
                Button {
                    openWindow(id: "updateWindow")
                } label: {
                    Text("Check for Update")
                }
                
                Divider()
                
                Link("Discuss macLlama on GitHub", destination: URL(string: "https://github.com/hellotunamayo/macLlama/discussions")!)
                Link("macLlama on GitHub", destination: URL(string: "https://github.com/hellotunamayo/macLlama")!)
            }
            
            CommandGroup(after: .appInfo) {
                Button {
                    openWindow(id: "updateWindow")
                } label: {
                    Text("Check for Update")
                }
            }
        }
        
        //MARK: Menu bar extra
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
        .windowResizability(.contentSize)
        
        //MARK: New version available
        Window("Check for Update", id: "updateWindow") {
            UpdatePanelView(updateData: $updateData)
        }
        .windowResizability(.contentSize)
        
        Window("Chat History", id: "chatHistory") {
            NavigationStack {
                ChatHistoryView()
                    .frame(minWidth: 400, minHeight: 400)
            }
        }
        .keyboardShortcut("h", modifiers: [.command, .shift], localization: .automatic)
        .modelContainer(for: SwiftDataChatHistory.self)
        .windowResizability(.contentSize)
    }
}

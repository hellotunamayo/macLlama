//
//  OllamaUIAppApp.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/7/25.
//

import SwiftUI
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
                //check for updates
                let lastUpdateCheckDate = UserDefaults.standard.integer(forKey: "lastUpdateCheckDate")
                let intervalSinceLastCheck: TimeInterval = Date().timeIntervalSince1970 - TimeInterval(lastUpdateCheckDate)
                
                do {
                    if intervalSinceLastCheck < 60 * 60 * 24 {
                        let githubService = GithubService()
                        guard let checkVersionResult = try await githubService.checkForUpdates() else { return }
                        self.updateData = checkVersionResult
                        openWindow(id: "updateWindow")
                        self.lastUpdateCheckDate = Date().timeIntervalSince1970
                        
                        #if DEBUG
                        debugPrint("updated checked in : \(UserDefaults.standard.integer(forKey: "lastUpdateCheckDate"))")
                        #endif
                    }
                } catch {
                    
                }
            }
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
        
        //MARK: New version available
        Window("macLlama update", id: "updateWindow") {
            VStack(alignment: .leading) {
                HStack {
                    Image("macLlama-profile")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .aspectRatio(contentMode: .fit)
                        .clipShape(Circle())
                        .padding(.trailing, 3)
                    
                    Text("New macLlama is available!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.bottom, 10)
                
                Text("We’ve released a **new version of macLlama!** To enjoy the latest features and improvements, please update your app now.")
                    .font(.title3)
                    .padding(.bottom, 10)
                
                Divider()
                
                ScrollView {
                    VStack {
                        Markdown{
                            MarkdownContent(self.updateData.body)
                        }
                        .padding()
                    }
                }
                .frame(height: 500)
                
                Divider()
                
                Spacer()
                
                VStack {
                    Link(destination: URL(string: self.updateData.htmlURL) ?? URL(fileURLWithPath: "")) {
                        Label("Click here to update", systemImage: "safari")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.vertical)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(width: 500, height: 700)
            .padding()
        }
        .windowResizability(.contentSize)
    }
}

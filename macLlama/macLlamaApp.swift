//
//  OllamaUIAppApp.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/7/25.
//

import SwiftUI
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true //This causes the app to quit when the last window is closed.
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        #if !DEBUG
        ShellService.killOllama()
        #endif
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
    }
}

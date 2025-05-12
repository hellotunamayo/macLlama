//
//  OllamaUIAppApp.swift
//  OllamaUIApp
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
        ShellService.killOllama()
        print("✅ applicationWillTerminate triggered")
    }
}

@main
struct OllamaUIAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State var ollama: OllamaNetworkService?

    var body: some Scene {
        Window("Ollama UI App", id: "main") {
            NavigationStack {
                ConversationView(ollamaNetworkService: ollama)
                    .navigationTitle("Conversation with Ollama")
            }
            .frame(minWidth: Units.appFrameMinWidth, idealWidth: Units.appFrameMinWidth,
                   minHeight: Units.appFrameMinHeight, idealHeight: Units.appFrameMinHeight)
        }
    }
}

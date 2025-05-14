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
        ShellService.killOllama()
        print("✅ applicationWillTerminate triggered")
    }
}

@main
struct macLlamaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State var ollama: OllamaNetworkService?

    var body: some Scene {
        Window("macLlama", id: "main") {
            NavigationStack {
                ConversationView(ollamaNetworkService: ollama)
                    .navigationTitle("macLlama")
            }
            .frame(minWidth: Units.appFrameMinWidth, idealWidth: Units.appFrameMinWidth,
                   minHeight: Units.appFrameMinHeight, idealHeight: Units.appFrameMinHeight)
        }
        
        MenuBarExtra("macLlama", image: "macLlama-menuIcon") {
            let versionString: Any = Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? ""
            let buildString: Any = Bundle.main.infoDictionary?["CFBundleVersion"] ?? ""
            Text("macLlama v\(versionString) (\(buildString))")
            
            Divider()
            
            Button {
                Task {
                    await ShellService.runShellScript("ollama serve")
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
            
            #if DEBUG
            Button {
                Task {
                    await ShellService.runShellScript("killall ollama")
                }
            } label: {
                Text("Kill Ollama server")
                    .foregroundStyle(.red)
            }
            #endif
            
            Divider()
            
            Link("Check for Update", destination: URL(string: "https://github.com/hellotunamayo/macLlama/releases")!)
            Link("macLlama on GitHub", destination: URL(string: "https://github.com/hellotunamayo/macLlama")!)
            
            Divider()
            
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit macLlama")
            }
        }
        
    }
}

//
//  MenuBarExtraView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/14/25.
//

import SwiftUI

struct MenuBarExtraView: View {
    @EnvironmentObject var serverStatus: ServerStatus
    
    let versionString: Any = Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? ""
    let buildString: Any = Bundle.main.infoDictionary?["CFBundleVersion"] ?? ""
    
    var body: some View {
        VStack {
            Text("macLlama v\(versionString) (\(buildString))")
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
            
            Button("Stop Local Ollama server", role: .destructive) {
                Task {
                    let _ = ShellService.killOllama()
                    try await Task.sleep(for: .seconds(1))
                    try? await serverStatus.updateServerStatus()
                }
            }

            Divider()
            
            Link("Search models from Ollama", destination: URL(string: "https://ollama.com/search")!)
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

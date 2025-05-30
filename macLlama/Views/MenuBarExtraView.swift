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
                Text("Ollama server is \(serverStatus.indicator ? "on" : "off")")
                    .foregroundStyle(serverStatus.indicator ? .green : .red)
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
                        
                        debugPrint(serverStatus)
                    }
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
                    let _ = try await ShellService.runShellScript("killall ollama")
                    try await Task.sleep(for: .seconds(1))
                    try? await serverStatus.updateServerStatus()
                }
            } label: {
                Text("Kill Ollama server")
                    .foregroundStyle(.red)
            }
            #endif
            
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

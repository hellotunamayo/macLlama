//
//  MenuBarExtraView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/14/25.
//

import SwiftUI

struct MenuBarExtraView: View {
    @Environment(\.scenePhase) var scenePhase
    @State private var isServerOnline: Bool = false
    let versionString: Any = Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? ""
    let buildString: Any = Bundle.main.infoDictionary?["CFBundleVersion"] ?? ""
    
    var body: some View {
        VStack {
            Text("macLlama v\(versionString) (\(buildString))")
            
            Divider()
            
            Button {
                Task {
                    if let serverStatus: Bool = try? await OllamaNetworkService.isServerOnline() {
                        self.isServerOnline = serverStatus
                    } else {
                        self.isServerOnline = false
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
        .onChange(of: scenePhase) { _, _ in
            Task {
                let serverStatus = try await OllamaNetworkService.isServerOnline()
                self.isServerOnline = serverStatus ? true : false
                debugPrint(self.isServerOnline)
            }
        }
    }
}

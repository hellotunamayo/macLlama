//
//  StartServerView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/12/25.
//

import SwiftUI

struct StartServerView: View {
    @EnvironmentObject var serverStatus: ServerStatus
    @State private var ollamaWarningBouncingYOffset: CGFloat = 0
    
    let ollamaNetworkService: OllamaNetworkService = OllamaNetworkService()
    
    var body: some View {
        VStack {
            HStack {
                Text("mac")
                    .font(.system(size: Units.appFrameMinWidth * 0.15, weight: .thin, design: .default))
                    .padding(.trailing, Units.appFrameMinWidth * -0.015)
                Text("Llama")
                    .font(.system(size: Units.appFrameMinWidth * 0.15, weight: .medium, design: .default))
            }
            .padding(.bottom, -5)
            
            Image("macLlama-profile")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: Units.appFrameMinWidth / 3,
                       maxHeight: Units.appFrameMinHeight / 4)
                .foregroundStyle(.yellow)
                .background(Color(nsColor: NSColor.windowBackgroundColor))
                .clipShape(Circle())
                .shadow(color:.black.opacity(0.2), radius: 3)
                .offset(y: ollamaWarningBouncingYOffset)
                .onAppear {
                    withAnimation(.bouncy(duration: 1.5, extraBounce: 1).repeatForever()){
                        self.ollamaWarningBouncingYOffset = 3
                    }
                }
            
            Text("Start your local AI engine\nwith Ollama")
                .fontWeight(.regular)
                .font(.title)
                .multilineTextAlignment(.center)
                .padding(.top, Units.normalGap)
            
            Button {
                Task {
                    let shellCommand: String = ShellCommand.startServer.rawValue
                    guard let _ = try await ShellService.runShellScript(shellCommand) else { return }
                    try? await Task.sleep(for: .seconds(1))
                    try await serverStatus.updateServerStatus()
                }
            } label: {
                Label("Start the server and go", systemImage: "power")
                    .padding(.trailing, Units.normalGap / 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, Units.normalGap / 2)
            
            Divider()
                .frame(maxWidth: 30)
                .padding(.vertical, Units.normalGap)
            
            Text("If the service fails to start, please check\nthat the Ollama server is installed on your system")
                .foregroundStyle(Color.gray)
                .lineSpacing(Units.normalGap / 5)
                .multilineTextAlignment(.center)
                .font(.subheadline)
            
            Link("Bug report or feature request", destination: URL(string: "https://github.com/hellotunamayo/macLlama/discussions")!)
                .font(.subheadline)
                .padding(.top, Units.normalGap / 2)
        }
        .padding(60)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: NSColor.windowBackgroundColor))
                .shadow(radius: 3)
        )
    }
}

//
//  OllamaUIAppApp.swift
//  OllamaUIApp
//
//  Created by Minyoung Yoo on 5/7/25.
//

import SwiftUI

@main
struct OllamaUIAppApp: App {
    var ollama: OllamaNetworkService = OllamaNetworkService(stream: false)

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ConversationView(ollamaNetworkService: ollama)
                    .navigationTitle("Conversation with Ollama")
            }
            .frame(minWidth: Units.appFrameMinWidth, idealWidth: Units.appFrameMinWidth,
                   minHeight: Units.appFrameMinHeight, idealHeight: Units.appFrameMinHeight)
        }
        .commands {
            CommandMenu("Utility") {
                Button("Reload Model List") {
                    Task {
                        try await ollama.getModels()
                    }
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }
}

//
//  ExperimentalView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/15/25.
//

import SwiftUI

struct ExperimentalView: View {
    @State private var text: String = ""
    @State private var prompt: String = ""
    
    let chatService = OllamaChatService()
    
    var body: some View {
        VStack {
            Text("Experimental feature\nfor next version in macLlama!")
                .font(.largeTitle)
            
            ScrollView {
                Text(text)
            }
            .frame(maxWidth: 800)
            
            TextField("Enter text", text: $prompt)
                .onSubmit {
                    Task {
                        try await self.sendChat(prompt: self.prompt)
                    }
                }
            Button {
                Task {
                    try await self.sendChat(prompt: self.prompt)
                }
            } label: {
                Text("run")
            }
        }
        .padding()
    }
    
    private func sendChat(prompt: String) async throws {
        let stream = try await chatService.sendMessage(model: "gemma3:4b", userInput: prompt)
        for await update in stream {
            print("Streaming: \(update)")
            text = update
        }
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
}

#Preview {
    ExperimentalView()
}

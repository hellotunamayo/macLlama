//
//  ExperimentalView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/15/25.
//

import SwiftUI

struct ChatMessage: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let role: String // "user" or "assistant"
    var content: String
}

actor OllamaChatService {
    private var messages: [ChatMessage] = []
    
    func sendMessage(userInput: String) async throws -> AsyncStream<String> {
        messages.append(ChatMessage(role: "user", content: userInput))
        
        guard let url = URL(string: "http://localhost:11434/api/chat") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gemma3:4b",
            "messages": try messages
                .map { try JSONEncoder().encode($0) }
                .map { try JSONSerialization.jsonObject(with: $0) },
            "stream": true
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (bytesStream, _) = try await URLSession.shared.bytes(for: request)
        
        var assistantContent = ""
        
        let stream = AsyncStream { continuation in
            Task {
                do {
                    for try await line in bytesStream.lines {
                        guard let data = line.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let message = json["message"] as? [String: Any],
                              let content = message["content"] as? String else {
                            continue
                        }
                        
                        assistantContent += content
                        continuation.yield(assistantContent)
                    }
                    
                    let finalMessage = ChatMessage(role: "assistant", content: assistantContent)
                    messages.append(finalMessage)
                    
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
        
        return stream
    }
    
    func allMessages() -> [ChatMessage] {
        return messages
    }
}

struct ExperimentalView: View {
    @State private var text: String = ""
    
    let chatService = OllamaChatService()
    
    var body: some View {
        VStack {
            Text(text)
            Button {
                Task {
                    try await self.test()
                }
            } label: {
                Text("run")
            }

        }
    }
    
    private func test() async throws {
        let stream = try await chatService.sendMessage(userInput: "Hello")
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

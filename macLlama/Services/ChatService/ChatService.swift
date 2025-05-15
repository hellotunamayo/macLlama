//
//  ChatService.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/15/25.
//

import Foundation

actor OllamaChatService {
    private(set) var messages: [ChatMessage] = []
    
    func sendMessage(model: String, userInput: String) async throws -> AsyncStream<String> {
        messages.append(ChatMessage(role: "user", content: userInput))
        
        guard let url = URL(string: "http://localhost:11434/api/chat") else {
            throw URLError(.badURL)
        }
        
        //Set request & header
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //Set request body
        let requestBody: [String: Any] = [
            "model": model,
            "messages": try messages.map { try JSONEncoder().encode($0) }
                                    .map { try JSONSerialization.jsonObject(with: $0) },
            "stream": true
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (bytesStream, _) = try await URLSession.shared.bytes(for: request)
        
        //Prepare response from Ollama
        var assistantContent = ""
        
        //Broadcast model response chunks
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
    
    ///Return full conversation list
    func allMessages() -> [ChatMessage] {
        return messages
    }
}

//
//  ChatService.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/15/25.
//

import SwiftUI

actor OllamaChatService {
    private(set) var messages: [ChatMessage] = []
    
    func sendMessage(model: String, userInput: String, images: [NSImage]?) async throws -> AsyncStream<String> {
        //Convert NSImage to base64
        let imageStrings = await nsImageArrayToBase64Array(images)
        
        messages.append(ChatMessage(role: "user", content: userInput, images: imageStrings))
        
        guard let url = URL(string: "http://localhost:11434/api/chat") else {
            throw URLError(.badURL)
        }
        
        //Set request & header
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //Set request body
        var requestBody: [String: Any] = [:]
        
        requestBody = [
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
                    
                    let finalMessage = ChatMessage(role: "assistant", content: assistantContent, images: nil)
                    messages.append(finalMessage)
                    
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
        
        return stream
    }
    
    ///Convert NSImage array to Base64 String array
    private func nsImageArrayToBase64Array(_ images: [NSImage]?) async -> [String]? {
        var base64Strings: [String] = []
        
        guard let images = images else {
            return nil
        }
        
        for image in images {
            guard let base64String = await nsImageToBase64(image) else { return nil }
            base64Strings.append(base64String)
        }
        return base64Strings
    }
    
    ///Convert NSImage to Base64 String
    private func nsImageToBase64(_ image: NSImage) async -> String? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }
        return pngData.base64EncodedString()
    }
    
    ///Return full conversation list
    func allMessages() -> [ChatMessage] {
        return messages
    }
}

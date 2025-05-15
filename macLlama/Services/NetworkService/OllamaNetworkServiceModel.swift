//
//  OllamaNetworkServiceModel.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/8/25.
//
import Foundation

struct OllamaChatMessage: Codable {
    let role: String
    let content: String
}

struct OllamaRequest: Encodable {
    let model: String
    let messages: [OllamaChatMessage]
    let stream: Bool
}

struct OllamaChatResponse: Codable {
    let model: String
    let createdAt: String
    let message: OllamaChatMessage
    let done: Bool
    let doneReason: String?
    
    enum CodingKeys: String, CodingKey {
        case model, message, done
        case createdAt = "created_at"
        case doneReason = "done_reason"
    }
}

struct OllamaResponse: Codable {
    let model: String
    let createdAt: String
    let message: String
    let done: Bool
    let doneReason: String?
    let context: [Int]
    
    enum CodingKeys: String, CodingKey {
        case model, done, context
        case message = "response"
        case createdAt = "created_at"
        case doneReason = "done_reason"
    }
}

struct OllamaModels: Codable {
    let models: [OllamaModel]
}

struct OllamaModel: Hashable, Codable {
    let name: String
    let model: String
}

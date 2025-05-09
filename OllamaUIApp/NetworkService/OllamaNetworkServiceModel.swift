//
//  OllamaNetworkServiceModel.swift
//  OllamaUIApp
//
//  Created by Minyoung Yoo on 5/8/25.
//
import Foundation

struct ContextDatum: Codable {
    let role: String
    let content: String
}

struct OllamaRequest: Encodable {
    let model: String
    let messages: [ContextDatum]
    let stream: Bool
}

struct OllamaChatResponse: Codable {
    let model: String
    let createdAt: String
    let message: ContextDatum
    
    enum CodingKeys: String, CodingKey {
        case model, message
        case createdAt = "created_at"
    }
}

struct OllamaResponse: Codable {
    let model: String
    let createdAt: String
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case model
        case message = "response"
        case createdAt = "created_at"
    }
}

struct OllamaModels: Codable {
    let models: [OllamaModel]
}

struct OllamaModel: Hashable, Codable {
    let name: String
    let model: String
}

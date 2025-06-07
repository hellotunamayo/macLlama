//
//  ChatServiceModel.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/15/25.
//

import Foundation

struct OllamaChatMessage: Codable {
    let role: String
    let content: String
}

struct LocalChatHistory: Identifiable, Hashable {
    let id: UUID = .init()
    let isUser: Bool
    let modelName: String
    var message: String
    var assistantThink: String?
}

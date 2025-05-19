//
//  ChatModel.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/14/25.
//

import Foundation

struct Chat: Identifiable {
    var id: UUID = UUID()
    let message: String
    let isUser: Bool
    let modelName: String
    let done: Bool
}

struct ChatMessage: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let role: String
    var content: String
    let images: [String]?
}

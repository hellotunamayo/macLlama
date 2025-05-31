//
//  ChatModel.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/14/25.
//

import Foundation

struct APIChat: Identifiable {
    var id: UUID = UUID()
    let message: String
    let isUser: Bool
    let modelName: String
    let done: Bool
}

struct APIChatMessage: Identifiable, Codable {
    var id: UUID = UUID()
    let role: String
    var content: String
    let images: [String]?
    let options: [APIChatOption]?
}

struct APIChatOption: Codable {
    let key: String
    let value: Double
}

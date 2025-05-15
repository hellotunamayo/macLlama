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

//
//  OllamaNetworkServiceModel.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/8/25.
//
import Foundation

struct OllamaModels: Codable {
    let models: [OllamaModel]
}

struct OllamaModel: Hashable, Codable {
    let name: String
    let model: String
}

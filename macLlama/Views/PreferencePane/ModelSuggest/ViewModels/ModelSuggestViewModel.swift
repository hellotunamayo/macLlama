//
//  ModelSuggestViewModel.swift
//  macLlama
//
//  Created by Minyoung Yoo on 7/20/25.
//

import Foundation

actor ModelSuggestionViewModel {
    private(set) var suggestionModels: [SuggestionModel] = [
        //gemma3
        SuggestionModel(purpose: [.generalChat, .writing, .creativeJob, .etcetera], modelName: "Gemma3", fullName: "gemma3:1b", modelParameterCount: 1_000_000_000),
        SuggestionModel(purpose: [.generalChat, .writing, .creativeJob, .etcetera], modelName: "Gemma3", fullName: "gemma3:4b", modelParameterCount: 4_000_000_000),
        SuggestionModel(purpose: [.generalChat, .writing, .creativeJob, .etcetera], modelName: "Gemma3", fullName: "gemma3:12b", modelParameterCount: 12_000_000_000),
        SuggestionModel(purpose: [.generalChat, .writing, .creativeJob, .etcetera], modelName: "Gemma3", fullName: "gemma3:27b", modelParameterCount: 27_000_000_000),
        //llama3
        SuggestionModel(purpose: [.generalChat, .writing, .creativeJob, .etcetera], modelName: "Llama3.2", fullName: "llama3.2:1b", modelParameterCount: 1_000_000_000),
        SuggestionModel(purpose: [.generalChat, .writing, .creativeJob, .etcetera], modelName: "Llama3.2", fullName: "llama3.2:3b", modelParameterCount: 3_000_000_000),
        //phi3
        SuggestionModel(purpose: [.generalChat, .writing, .creativeJob, .etcetera], modelName: "Phi3", fullName: "phi3:3.8b", modelParameterCount: 3_800_000_000),
        SuggestionModel(purpose: [.generalChat, .writing, .creativeJob, .etcetera], modelName: "Phi3", fullName: "phi3:14b", modelParameterCount: 14_000_000_000),
        //codellama
        SuggestionModel(purpose: [.codeGeneration], modelName: "CodeLlama", fullName: "codellama:7b", modelParameterCount: 7_000_000_000),
        SuggestionModel(purpose: [.codeGeneration], modelName: "CodeLlama", fullName: "codellama:13b", modelParameterCount: 13_000_000_000),
        SuggestionModel(purpose: [.codeGeneration], modelName: "CodeLlama", fullName: "codellama:34b", modelParameterCount: 34_000_000_000),
        //qwen2.5 coder
        SuggestionModel(purpose: [.codeGeneration], modelName: "Qwen2.5-coder", fullName: "qwen2.5-coder:1.5b", modelParameterCount: 1_500_000_000),
        SuggestionModel(purpose: [.codeGeneration], modelName: "Qwen2.5-coder", fullName: "qwen2.5-coder:3b", modelParameterCount: 3_000_000_000),
        SuggestionModel(purpose: [.codeGeneration], modelName: "Qwen2.5-coder", fullName: "qwen2.5-coder:7b", modelParameterCount: 7_000_000_000),
        SuggestionModel(purpose: [.codeGeneration], modelName: "Qwen2.5-coder", fullName: "qwen2.5-coder:14b", modelParameterCount: 14_000_000_000),
        //deepseek coder
        SuggestionModel(purpose: [.codeGeneration], modelName: "Deepseek-coder", fullName: "deepseek-coder:1.3b", modelParameterCount: 1_300_000_000),
        SuggestionModel(purpose: [.codeGeneration], modelName: "Deepseek-coder", fullName: "deepseek-coder:6.7b", modelParameterCount: 6_700_000_000),
        SuggestionModel(purpose: [.codeGeneration], modelName: "Deepseek-coder", fullName: "deepseek-coder:33b", modelParameterCount: 33_000_000_000),
        //llava
        SuggestionModel(purpose: [.vision], modelName: "Llava", fullName: "llava:7b", modelParameterCount: 7_000_000_000),
        SuggestionModel(purpose: [.vision], modelName: "Llava", fullName: "llava:13b", modelParameterCount: 13_000_000_000),
        SuggestionModel(purpose: [.vision], modelName: "Llava", fullName: "llava:34b", modelParameterCount: 34_000_000_000),
    ]
    
    func modelSuggestionBy(purpose: [SuggestionModelPurpose]) async -> [SuggestionModel] {
        var models: Set<SuggestionModel> = []
        purpose.forEach { purpose in
            self.suggestionModels.filter { $0.purpose.contains(purpose) }.forEach { models.insert($0) }
        }
        let result = models.sorted { $0.modelName < $1.modelName }
        return result
    }
    
    func modelSuggestionBy(memory: UInt64, from models: [SuggestionModel]) -> [SuggestionModel] {
        var result: [SuggestionModel] = []
        models.filter { $0.modelParameterCount <= memory }.sorted { $0.modelParameterCount < $1.modelParameterCount }.forEach { result.append($0) }
        return result
    }
}


//
//  NetworkService.swift
//  OllamaUIApp
//
//  Created by Minyoung Yoo on 5/7/25.
//
import Foundation

protocol OllamaNetworkServiceUser {
    var ollamaService: OllamaNetworkService? { get set }
}

actor OllamaNetworkService: ObservableObject {
    private(set) var modelName: String?
    private(set) var stream: Bool
    
    init(stream: Bool) {
        self.stream = stream
        Task {
            await self.setInitialModel()
        }
    }
    
    ///Checks Ollama server is online.
    func isServerOnline() async throws {
        do {
            let urlString: String = "http://127.0.0.1:11434"
            guard let url = URL(string: urlString) else { throw URLError(.badURL) }
            let (_, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            
            if 200..<300 ~= response.statusCode {
                return
            } else {
                throw URLError(.badServerResponse)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    ///Get all available models from Ollama server.
    func getModels() async throws -> [OllamaModel]? {
        do {
            try await self.isServerOnline()
            let urlString: String = "http://127.0.0.1:11434/api/tags"
            guard let url = URL(string: urlString) else { throw URLError(.badURL) }
            let (data, _) = try await URLSession.shared.data(from: url)
            let modelList = try JSONDecoder().decode(OllamaModels.self, from: data)
            return modelList.models
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    ///Change current model.
    func changeModel(model: String) {
        self.modelName = model
    }
    
    ///Make chat history array for maintaing conversation context.
    func makePromptWithContext(chatContext: [Chat], currentUserPrompt: ContextDatum) throws -> [ContextDatum] {
        var data: [ContextDatum] = []
        chatContext.forEach { chat in
            let newElement: ContextDatum = ContextDatum(role: chat.isUser ? "user" : "assistant",
                                                                    content: chat.message)
            data.append(newElement)
        }
        
        return data
    }
    
    func sendConversationRequest(prompt: String, context: [Chat]) async throws -> OllamaChatResponse? {
        do {
            //Set Context
            let userPrompt: ContextDatum = ContextDatum(role: "user", content: prompt)
            let promptWithContext = try makePromptWithContext(chatContext: context, currentUserPrompt: userPrompt)
            
            //Check server status
            try await self.isServerOnline()
            
            //Preparing url
            let urlString: String = "http://127.0.0.1:11434/api/chat"
            guard let url = URL(string: urlString) else { throw URLError(.badURL) }
            
            //Check model availability
            guard let modelName = self.modelName else { throw OllamaError.modelNotFound }
            
            //Preparing request
            let ollamaRequest = OllamaRequest(model: modelName, messages: promptWithContext, stream: self.stream)
            let jsonData = try JSONEncoder().encode(ollamaRequest)
            
            //Send Request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            //Process Response
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            
            switch httpResponse.statusCode {
                case 200..<300:
                    let ollamaResponse = try JSONDecoder().decode(OllamaChatResponse.self, from: data)
                    return ollamaResponse
                default:
                    print("Failed to fetch data")
                    return nil
            }
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func setInitialModel() async {
        Task {
            guard let models = try await self.getModels() else { return }
            self.modelName = models.first?.name ?? nil
        }
    }
}

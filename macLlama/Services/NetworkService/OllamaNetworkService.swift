//
//  NetworkService.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/7/25.
//
import Foundation

protocol OllamaNetworkServiceUser {
    var ollamaNetworkService: OllamaNetworkService? { get set }
}

actor OllamaNetworkService {
    private(set) var modelName: String?
    private(set) var stream: Bool
    
    init(stream: Bool) {
        self.stream = stream
        Task {
            await self.setInitialModel()
        }
    }
    
    ///Checks Ollama server is online.
    static func isServerOnline() async throws -> Bool {
        do {
            let urlString: String = "http://127.0.0.1:11434"
            guard let url = URL(string: urlString) else { return false }
            let (_, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse else { return false }
            
            switch response.statusCode {
                case 200..<300:
                    return true
                default:
                    return false
            }
        } catch {
//            debugPrint(error.localizedDescription)
            return false
        }
    }
    
    ///Get all available models from Ollama server.
    static func getModels() async throws -> [OllamaModel]? {
        do {
            if try await OllamaNetworkService.isServerOnline() {
                let urlString: String = "http://127.0.0.1:11434/api/tags"
                guard let url = URL(string: urlString) else { throw URLError(.badURL) }
                let (data, _) = try await URLSession.shared.data(from: url)
                let modelList = try JSONDecoder().decode(OllamaModels.self, from: data)
                return modelList.models
            } else {
                return nil
            }
        } catch {
            debugPrint("Error: \(error.localizedDescription)")
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
    
    ///Send conversation request to Ollama Server
    func sendConversationRequest(prompt: String, context: [Chat]) async throws -> OllamaChatResponse? {
        do {
            //Set Context
            let userPrompt: ContextDatum = ContextDatum(role: "user", content: prompt)
            let promptWithContext = try makePromptWithContext(chatContext: context, currentUserPrompt: userPrompt)
            
            //Check server status
            if try await OllamaNetworkService.isServerOnline() == false {
                throw URLError(.badServerResponse)
            }
            
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
                    return nil
            }
        } catch {
            let contextDatum: ContextDatum = ContextDatum(role: "assistant", content: "Ollama Error: \(error.localizedDescription)")
            let ollamaErrorResponse = OllamaChatResponse(model: modelName ?? "Error Model", createdAt: Date().description,
                                                    message: contextDatum, done: false, doneReason: nil)
            debugPrint("Error: \(error.localizedDescription)")
            return ollamaErrorResponse
        }
    }
    
    ///Set initial model
    private func setInitialModel() async {
        Task {
            guard let models = try await OllamaNetworkService.getModels() else { return }
            self.modelName = models.first?.name ?? nil
        }
    }
}

//
//  NetworkService.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/7/25.
//
import Foundation

actor OllamaNetworkService {
    private(set) var modelName: String?
    
    init() {
        Task {
            await self.setInitialModel()
        }
    }
    
    ///Checks availability of Ollama server'
    static func isAvailable() async throws -> Bool {
        do {
            guard let shellResponse = try await ShellService.runShellScript("ollama") else { return false }
            
            let data = shellResponse.0.fileHandleForReading.availableData
            let output = String(data: data, encoding: .utf8) ?? ""
            if output.contains("command not found") {
#if DEBUG
                debugPrint("Ollama is not available")
#endif
                
                return false
            } else {
                return true
            }
        } catch {
#if DEBUG
            debugPrint("Ollama is not available")
#endif
            return false
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
    
    ///Set initial model
    private func setInitialModel() async {
        Task {
            guard let models = try await OllamaNetworkService.getModels() else { return }
            self.modelName = models.first?.name ?? nil
        }
    }
}

//
//  ContentView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/7/25.
//

import SwiftUI
import SwiftData
import MarkdownUI

struct ConversationView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var serverStatus: ServerStatusIndicator
    
    @State private var history: [(isUser: Bool, modelName: String, message: String)] = []
    @State private var prompt: String = ""
    @State private var modelList: [OllamaModel] = []
    @State private var currentModel: String = ""
    @State private var isThinking: Bool = false
    @State private var isModelLoading: Bool = false
    @State private var tempMessage: String = ""
    
    let chatService: OllamaChatService = OllamaChatService()
    let ollamaNetworkService: OllamaNetworkService = OllamaNetworkService()
    let ollamaProfilePicture: NSImage? = NSImage(named: "llama_gray")
    
    var body: some View {
        ZStack {
            //MARK: Background View(Llama Image)
            if !self.currentModel.isEmpty {
                ChatBackgroundView()
            }
            
            //MARK: Conversation view
            VStack {
                if !self.modelList.isEmpty {
                    ModelSelectView(modelList: $modelList, currentModel: $currentModel,
                                    isModelLoading: $isModelLoading, ollamaNetworkService: self.ollamaNetworkService) {
                        Task {
                            try? await self.initModelList()
                        }
                    }
                    
                    Divider()
                        .foregroundStyle(Color(nsColor: .systemGray))
                        .opacity(self.colorScheme == .dark ? 1.0 : 0.9)
                }
                
                //experimental
                ScrollViewReader { proxy in
                    ScrollView {
                        ForEach(0..<self.history.count, id: \.self) { index in
                            if history[index].message != "" {

                                ChatBubbleView(chatData: history[index])
                                    .padding()
                                    .id(index)
                                
                                Divider()
                                    .foregroundStyle(Color(nsColor: .systemGray))
                                    .opacity(self.colorScheme == .dark ? 1.0 : 0.9)
                            } else {
                                VStack {
                                    ProgressView()
                                        .frame(width: 14, height: 14)
                                        .padding(.bottom)
                                    
                                    Text("Ollama is Thinking...")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                            }
                        }
                    }
                    .onChange(of: history.count) { _, _ in
                        withAnimation {
                            proxy.scrollTo(history.count - 1, anchor: .bottom)
                        }
                    }
                }
                
                //MARK: Input Area
                if !self.modelList.isEmpty {
                    ChatInputView(isThinking: $isThinking, prompt: $prompt) {
                        self.history.append((isUser: true, modelName: self.currentModel, message: self.prompt))
                        self.isThinking = true
                        try await self.sendChat(model: self.currentModel, prompt: self.prompt)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(modelList.isEmpty ? 0.1 : 1)
            .overlay {
                if self.modelList.isEmpty {
                    StartServerView() {
                        try await self.initModelList()
                    }
                    .padding(.top, Units.normalGap * -3)
                }
            }
        }
    }
}

//MARK: Internal functions
extension ConversationView {
    ///Send Chat to Ollama server
    private func sendChat(model: String, prompt: String) async throws {
        if try await OllamaNetworkService.isServerOnline() { //server online check
            //Reset user prompt
            self.prompt.removeAll()
            
            self.history.append((isUser: false, modelName: self.currentModel, message: ""))
            
            //Start stream from model
            let stream = try await chatService.sendMessage(model: model, userInput: prompt)
            for await update in stream {
                self.history[self.history.count - 1].message = update
            }
            
            //Action when stream ends
            self.history[self.history.count - 1].message = await chatService.allMessages().last?.content ?? ""
            self.isThinking = false
        } else {
            debugPrint("ConversationViewError:")
            debugPrint("Server is not online")
            serverStatus.updateServerStatusIndicatorTo(false)
            self.modelList.removeAll()
            self.isThinking = false
        }
    }
    
    ///Initialize Model List
    private func initModelList() async throws {
        do {
            if let serverStatus = try? await OllamaNetworkService.isServerOnline() {
                self.serverStatus.updateServerStatusIndicatorTo(serverStatus)
                modelList = try await OllamaNetworkService.getModels() ?? []
                currentModel = modelList.first?.name ?? ""
                await self.ollamaNetworkService.changeModel(model: currentModel)
            }
        } catch {
            debugPrint("ConversationViewError:")
            debugPrint("Error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ConversationView()
        .modelContainer(for: Item.self, inMemory: true)
}

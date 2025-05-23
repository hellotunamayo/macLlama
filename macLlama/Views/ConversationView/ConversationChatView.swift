//
//  ConversationChatView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/17/25.
//

import SwiftUI

struct ConversationChatView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var serverStatus: ServerStatus
    
    //Model selector state
    @State private var currentModel: String = ""
    @State private var isModelLoading: Bool = false
    
    //Request state
    @State private var prompt: String = ""
    @State private var modelList: [OllamaModel] = []
    @State private var isThinking: Bool = false
    @State private var promptImages: [NSImage] = []
    
    //Chat history state
    @State private var history: [(isUser: Bool, modelName: String, message: String)] = []
    
    //Auto scrolling state
    @State private var isAutoScrolling: Bool = false
    @State private var autoScrollTask: Task<Void, Never>?
    
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
                
                ScrollViewReader { proxy in
                    ScrollView {
                        ForEach(0..<self.history.count, id: \.self) { index in
                            LazyVStack {
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
                    }
                    .onChange(of: history.count) { _, _ in
                        let isAutoScroll = UserDefaults.standard.bool(forKey: "isAutoScrollEnabled")
                        if isAutoScroll {
                            autoScrollTask = Task {
                                while !Task.isCancelled {
                                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                                    
                                    withAnimation(.linear(duration: 2.0)) {
                                        proxy.scrollTo(history.count - 1, anchor: .bottom)
                                    }
                                    
                                    if !isAutoScrolling {
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
                
#if DEBUG
                Button {
                    self.history = []
                } label: {
                    Label("Clear View", systemImage: "trash")
                }
#endif
                
                //MARK: Input Area
                if !self.modelList.isEmpty {
                    ChatInputView(isThinking: $isThinking, prompt: $prompt, images: $promptImages) {
                        self.history.append((isUser: true, modelName: self.currentModel, message: self.prompt))
                        self.isThinking = true
                        
                        //Check if suffix exists
                        guard let suffix = UserDefaults.standard.string(forKey: "promptSuffix") else { return }
                        let promptWithSuffix: String = self.prompt + " \(suffix)"
                        
                        try await self.sendChat(model: self.currentModel, prompt: promptWithSuffix, images: self.promptImages)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(modelList.isEmpty ? 0.1 : 1)
            .task {
                try? await self.initModelList()
            }
        }
    }
}


//MARK: Internal functions
extension ConversationChatView {
    ///Send Chat to Ollama server
    private func sendChat(model: String, prompt: String, images: [NSImage]) async throws {
        if try await OllamaNetworkService.isServerOnline() { //server online check
            //Reset user prompt
            self.prompt.removeAll()
            
            //Enable auto scrolling if setting is on
            let isAutoScroll = UserDefaults.standard.bool(forKey: "isAutoScrollEnabled")
            if isAutoScroll {
                self.isAutoScrolling = true
            } else {
                self.isAutoScrolling = false
            }
            
            self.history.append((isUser: false, modelName: self.currentModel, message: ""))
            
            //Start stream from model
            Task {
                let stream = try await chatService.sendMessage(model: model, userInput: prompt, images: images)
                for await update in stream {
                    self.history[self.history.count - 1].message = update
                }
                
                //Save last response to history
                self.history[self.history.count - 1].message = await chatService.allMessages().last?.content ?? ""
                
                //Reset state
                self.isThinking = false
                self.isAutoScrolling = false
                self.autoScrollTask = nil
            }
        } else {
            debugPrint("ConversationViewError:")
            debugPrint("Server is not online")
            try? await serverStatus.updateServerStatus()
            self.modelList.removeAll()
            
            //Reset state
            self.isThinking = false
            self.isAutoScrolling = false
            self.autoScrollTask = nil
        }
    }
    
    ///Check server status
    private func checkServerStatus() async throws -> Bool {
        if let serverStatus = try? await OllamaNetworkService.isServerOnline() {
            return serverStatus
        } else {
            return false
        }
    }
    
    ///Initialize Model List
    private func initModelList() async throws {
        do {
            try? await serverStatus.updateServerStatus()
            self.modelList = try await OllamaNetworkService.getModels() ?? []
            
            if !modelList.isEmpty {
                guard let firstModel = modelList.first else { throw NSError(domain: "", code: 0, userInfo: nil) }
                await self.ollamaNetworkService.changeModel(model: firstModel.name)
                self.currentModel = firstModel.name
            }
        } catch {
            debugPrint("ConversationChatViewError:")
            debugPrint("Error: \(error.localizedDescription)")
        }
    }
}

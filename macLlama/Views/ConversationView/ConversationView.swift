//
//  ContentView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/7/25.
//

import SwiftUI
import SwiftData
import MarkdownUI

struct ConversationView: View, OllamaNetworkServiceUser {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var prompt: String = ""
    @State private var chatHistory: [Chat] = []
    @State private var modelList: [OllamaModel] = []
    @State private var currentModel: String = ""
    @State private var isThinking: Bool = false
    @State private var scrollToIndex: Int = 0
    @State private var isModelLoading: Bool = false
    @State private var isServerOnline: Bool = false
    @State internal var ollamaNetworkService: OllamaNetworkService?

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
                    ModelSelectView(isServerOnline: $isServerOnline, modelList: $modelList,
                                    currentModel: $currentModel, ollamaNetworkService: $ollamaNetworkService,
                                    isModelLoading: $isModelLoading) {
                        Task {
                            try? await self.initModelList()
                        }
                    }
                    
                    Divider()
                        .foregroundStyle(Color(nsColor: .systemGray))
                        .opacity(self.colorScheme == .dark ? 1.0 : 0.9)
                }
                
                //MARK: Chat Scroll View
                ScrollViewReader { proxy in
                    ScrollView {
                        ForEach(0..<self.chatHistory.count, id: \.self) { index in
                            
                            if chatHistory[index].done {
                                ChatBubbleView(chatData: chatHistory[index])
                                    .padding()
                                    .id(index)
                            } else {
                                VStack {
                                    Text("⚠️ Please check your Ollama server is running.")
                                        .multilineTextAlignment(.center)
                                        .padding()
                                        .background(
                                            Capsule().fill(.yellow.opacity(0.15))
                                        )
                                }
                                .padding()
                                
                                ChatBubbleView(chatData: chatHistory[index])
                                    .padding()
                                    .id(index)
                                    .background(
                                        Rectangle().fill(.red.opacity(0.15))
                                    )
                                
                                if !self.isServerOnline {
                                    Button {
                                        Task {
                                            guard let _ = await ShellService.runShellScript("ollama serve") else { return }
                                            
                                            //TODO: Replace this temporary solution!
                                            sleep(1)
                                            
                                            if let isServerOnline = try? await OllamaNetworkService.isServerOnline() {
                                                switch isServerOnline {
                                                    case true:
                                                        debugPrint("Server is online")
                                                        self.isServerOnline = true
                                                        ollamaNetworkService = OllamaNetworkService(stream: false)
                                                        try await self.initModelList()
                                                    case false:
                                                        return
                                                }
                                            }
                                            
                                        }
                                    } label: {
                                        Label("Restart Server", systemImage: "power")
                                    }
                                    .padding()
                                } else {
                                    Text("Server is now online")
                                        .foregroundStyle(Color(nsColor: .systemGray))
                                        .padding()
                                }
                            }
                            
                            Divider()
                                .foregroundStyle(Color(nsColor: .systemGray))
                                .opacity(self.colorScheme == .dark ? 1.0 : 0.9)
                            
                        }
                    }
                    .task {
                        try? await initModelList()
                    }
                    .onChange(of: scrollToIndex) { _, newValue in
                        self.scrollToIndex = newValue
                        withAnimation {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                }
                
                //MARK: Input Area
                if !self.modelList.isEmpty {
                    ChatInputView(isThinking: $isThinking, prompt: $prompt) {
                        try await self.sendMessage()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(modelList.isEmpty ? 0.1 : 1)
            .overlay {
                if self.modelList.isEmpty {
                    StartServerView(ollamaNetworkService: $ollamaNetworkService) {
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
    
    ///Send message to Ollama server
    private func sendMessage() async throws {
        if self.prompt.isEmpty {
            print("Prompt must be filled.")
            return
        }
        
        //Enter thinking state
        self.isThinking = true
        
        //Set user prompt
        let userChatModel = Chat(message: prompt, isUser: true, modelName: currentModel, done: true)
        chatHistory.append(userChatModel)
        
        //Filter the chat isn't error
        let filteredHistory = chatHistory.filter { $0.done == true }
        
        //Set response
        if let response = try await self.ollamaNetworkService?.sendConversationRequest(prompt: self.prompt,
                                                                                       context: filteredHistory) {
            self.isThinking = false
            // Clear prompt and end thinking state
            self.prompt = ""
            self.isThinking = false
            
            let responseChatModel = Chat(message: response.message.content, isUser: false,
                                         modelName: currentModel, done: response.done)
            
            if !responseChatModel.done {
                self.isServerOnline = false
            }
            
            chatHistory.append(responseChatModel)
            self.scrollToIndex = self.chatHistory.count - 1
        } else {
            self.isThinking = false
            print("Something Wrong!!")
        }
    }
    
    ///Initialize Model List
    private func initModelList() async throws {
        do {
            if let serverStatus = try? await OllamaNetworkService.isServerOnline() {
                self.isServerOnline = serverStatus
                modelList = try await ollamaNetworkService?.getModels() ?? []
                currentModel = modelList.first?.name ?? ""
                await self.ollamaNetworkService?.changeModel(model: currentModel)
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ConversationView()
        .modelContainer(for: Item.self, inMemory: true)
}

//
//  ContentView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/7/25.
//

import SwiftUI
import SwiftData
import MarkdownUI

struct Chat: Identifiable {
    var id: UUID = UUID()
    let message: String
    let isUser: Bool
    let modelName: String
}

struct ConversationView: View, OllamaNetworkServiceUser {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var prompt: String = ""
    @State private var chatHistory: [Chat] = []
    @State private var modelList: [OllamaModel] = []
    @State private var currentModel: String = ""
    @State private var isThinking: Bool = false
    @State private var scrollToIndex: Int = 0
    @State private var isModelLoading: Bool = false
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
                    HStack{
                        Picker("Current Model", selection: $currentModel) {
                            ForEach(modelList, id: \.self) { model in
                                Text(model.name)
                                    .foregroundStyle(.primary)
                                    .tag(model.name)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: Units.appFrameMinWidth * 0.5)
                        .onChange(of: currentModel) { oldValue, newValue in
                            Task {
                                await self.ollamaNetworkService?.changeModel(model: newValue)
                            }
                        }
                        
                        Button {
                            withAnimation {
                                self.isModelLoading.toggle()
                            }
                            
                            Task {
                                self.isModelLoading = true
                                try await self.initModelList()
                                self.isModelLoading = false
                            }
                        } label: {
                            VStack {
                                if self.isModelLoading {
                                    Label("Loading...", systemImage: "rays")
                                } else {
                                    Label("Reload", systemImage: "arrow.clockwise")
                                }
                            }
                            .padding(.vertical, Units.normalGap / 8)
                            .frame(width: 80)
                        }
                        .tint(.primary)
                        .controlSize(.regular)
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    
                    Divider()
                        .foregroundStyle(Color(nsColor: .systemGray))
                        .opacity(self.colorScheme == .dark ? 1.0 : 0.9)
                }
                
                //MARK: Chat Scroll View
                ScrollViewReader { proxy in
                    ScrollView {
                        ForEach(0..<self.chatHistory.count, id: \.self) { index in
                            
                            ChatBubbleView(chatData: chatHistory[index])
                                .padding()
                                .id(index)
                            
                            Divider()
                                .foregroundStyle(Color(nsColor: .systemGray))
                                .opacity(self.colorScheme == .dark ? 1.0 : 0.9)
                            
                        }
                    }
                    .task {
                        do {
                            try await self.initModelList()
                        } catch {
                            print("Error: \(error.localizedDescription)")
                        }
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
        let userChatModel = Chat(message: prompt, isUser: true, modelName: currentModel)
        chatHistory.append(userChatModel)
        
        //Set response
        guard let response = try await self.ollamaNetworkService?.sendConversationRequest(prompt: self.prompt, context: chatHistory) else {
            self.isThinking = false
            return
        }
        
        // Clear prompt and end thinking state
        self.prompt = ""
        self.isThinking = false
        
        let responseChatModel = Chat(message: response.message.content, isUser: false, modelName: currentModel)
        chatHistory.append(responseChatModel)
        
        self.scrollToIndex = self.chatHistory.count - 1
    }
    
    ///Initialize Model List
    private func initModelList() async throws {
        modelList = try await ollamaNetworkService?.getModels() ?? []
        currentModel = modelList.first?.name ?? ""
        await self.ollamaNetworkService?.changeModel(model: currentModel)
    }
}

#Preview {
    ConversationView()
        .modelContainer(for: Item.self, inMemory: true)
}

//
//  ConversationChatView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/17/25.
//

import SwiftUI
import Combine
import SwiftData

struct ChatInterfaceView: View {
    @AppStorage("currentSelectedPreference") var currentSelectedPreference: String?
    
    @Environment(\.openSettings) var openSettings
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) var modelContext
    @Environment(\.openWindow) var openWindow
    @EnvironmentObject var serverStatus: ServerStatus
    
    //Model selector state
    @State private var currentModel: String = ""
    @State private var isModelLoading: Bool = false
    
    //Request state
    @State private var prompt: String = ""
    @State private var modelList: [OllamaModel] = []
    @State private var isThinking: Bool = false
    @State private var promptImages: [NSImage] = []
    @State private var predict: Double = -1
    @State private var temperature: Double = 0.7
    
    //Chat history state
    @State private var history: [LocalChatHistory] = []
    
    //Auto scrolling state
    @State private var isAutoScrolling: Bool = false
    @State private var autoScrollTask: Task<Void, Never>?
    
    //Extra state
    @State private var conversationId: UUID = UUID()
    @State private var hoveredTopButtonTag: Int? = nil
    @State private var showThink: Bool = false
    @State private var advancedOptionDrawerVisibility: NavigationSplitViewVisibility = .detailOnly
    
    //Local prefix & suffix of prompt
    @State private var localPrefix: String = ""
    @State private var localSuffix: String = ""
    
    let chatService: OllamaChatService = OllamaChatService()
    let ollamaNetworkService: OllamaNetworkService = OllamaNetworkService()
    let ollamaProfilePicture: NSImage? = NSImage(named: "llama_gray")

    var body: some View {
        NavigationSplitView(columnVisibility: $advancedOptionDrawerVisibility) {
            ChatSidebarView(showThink: $showThink, localPrefix: $localPrefix, localSuffix: $localSuffix, predict: $predict, temperature: $temperature)
                .navigationSplitViewColumnWidth(min: 200, ideal: 280, max: 400)
        } detail: {
            ZStack {
                //MARK: Background View(Llama Image)
                if !self.currentModel.isEmpty {
                    ChatBackgroundView()
                }
                
                //MARK: Conversation view
                VStack {
                    if self.modelList.isEmpty {
                        //If model is not exists on Ollama server
                        Button {
                            self.currentSelectedPreference = "modelManagement"
                            openSettings()
                        } label: {
                            Label("Install Recommended Models", systemImage: "wand.and.sparkles.inverse")
                                .font(.title3)
                                .padding(.horizontal)
                        }
                        .controlSize(.large)
                        .symbolEffect(.pulse)
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                        
                        Button {
                            Task {
                                try await self.initModelList()
                            }
                        } label: {
                            Label("Reload model list", systemImage: "arrow.trianglehead.counterclockwise")
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    } else {
                        ModelSelectView(modelList: $modelList, currentModel: $currentModel,
                                        isModelLoading: $isModelLoading, ollamaNetworkService: self.ollamaNetworkService) {
                            Task {
                                try? await self.initModelList()
                            }
                        }
                        .zIndex(1)
                    }
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            ForEach(0..<self.history.count, id: \.self) { index in
                                VStack {
                                    if history[index].message != "" {
                                        ChatBubbleView(isThinking: self.$isThinking, chatData: $history[index])
                                            .padding()
                                            .id(index)
                                        
                                        if !history[index].isUser {
                                            Button {
                                                if index > 0 && !isThinking {
                                                    withAnimation {
                                                        proxy.scrollTo(index, anchor: .top)
                                                    }
                                                }
                                            } label: {
                                                if let hovered = self.hoveredTopButtonTag, hovered == index {
                                                    Text("Scroll to Top")
                                                        .padding(.horizontal)
                                                } else {
                                                    Image(systemName: "arrow.up")
                                                        .padding(.horizontal)
                                                }
                                            }
                                            .disabled(isThinking ? true : false)
                                            .buttonStyle(.bordered)
                                            .opacity(isThinking ? 0 : 0.7)
                                            .clipShape(.capsule)
                                            .padding()
                                            .onHover { enter in
                                                if enter {
                                                    withAnimation(.easeOut(duration: 0.3)) {
                                                        self.hoveredTopButtonTag = index
                                                    }
                                                } else {
                                                    withAnimation(.easeOut(duration: 0.3)) {
                                                        self.hoveredTopButtonTag = nil
                                                    }
                                                }
                                            }
                                        }
                                            
                                        Divider()
                                            .foregroundStyle(Color(nsColor: .systemGray))
                                            .opacity(self.colorScheme == .dark ? 1.0 : 0.9)
                                    } else {
                                        if isThinking {
                                            VStack {
                                                ProgressView()
                                                    .frame(width: 14, height: 14)
                                                    .padding(.bottom)
                                                
                                                Text("Ollama is Thinking...")
                                                    .font(.title3)
                                                    .foregroundStyle(.secondary)
                                            }
                                            .padding()
                                        } else {
                                            HStack {
                                                Image("ollama_warning")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: Units.normalGap * 3, height: Units.normalGap * 3)
                                                    .background(Color.white)
                                                    .clipShape(Circle())
                                                
                                                Text("An error occurred while processing your request.\nPlease try again later.")
                                                    .foregroundStyle(.secondary)
                                                    .font(.subheadline)
                                            }
                                            .padding()
                                        }
                                    }
                                }
                            }
                        }
                        .zIndex(0)
                        .onChange(of: isThinking) { _, newValue in
                            //Automatically scroll to the bottom when the answer is complete,
                            //if auto-scrolling is enabled.
                            if !newValue && UserDefaults.standard.bool(forKey: "isAutoScrollEnabled") {
                                withAnimation(.linear(duration: 2.0)) {
                                    proxy.scrollTo(history.count - 1, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: history.count) { _, _ in
                            if UserDefaults.standard.bool(forKey: "isAutoScrollEnabled") {
                                autoScrollTask = Task {
                                    while !Task.isCancelled {
                                        if self.isAutoScrolling == true {
                                            proxy.scrollTo(history.count - 1, anchor: .bottom)
                                            
                                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                                            
                                            if self.isAutoScrolling == false {
                                                break
                                            }
                                        }
                                    }
                                }
                            } else {
                                autoScrollTask = nil
                            }
                        }
                        .onAppear {
                            NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                                if isThinking {
                                    self.isAutoScrolling = false
                                    guard let autoScrollTask = self.autoScrollTask else { return event }
                                    autoScrollTask.cancel()
                                    self.autoScrollTask = nil
                                }
                                return event
                            }
                        }
                    }
                    
                    //MARK: Input Area
                    if self.modelList.count > 0 {
                        ChatInputView(isThinking: $isThinking, prompt: $prompt, images: $promptImages) {
                            if try await OllamaNetworkService.isServerOnline() {
                                Task {
                                    //Save user question to SwiftData
                                    let userChatMessage: APIChatMessage = APIChatMessage(role: "user", content: self.prompt,
                                                                                         images: nil, options: nil,
                                                                                         assistantThink: nil)
                                    await self.saveSwiftDataHistory(history: userChatMessage)
                                }
                                
                                //Append local chat history
                                let userQuestion: LocalChatHistory = LocalChatHistory(isUser: true,
                                                                                      modelName: self.currentModel,
                                                                                      message: self.prompt)
                                self.history.append(userQuestion)
                                self.isThinking = true
                                
                                //Check if prefix & suffix exists
                                let globalPrefix: String = UserDefaults.standard.string(forKey: "promptPrefix") ?? ""
                                let globalSuffix: String = UserDefaults.standard.string(forKey: "promptSuffix") ?? ""
                                let finalPrompt: String = globalPrefix + " " + self.localPrefix + " " + self.prompt + self.localSuffix + globalSuffix
                                try await self.sendChat(model: self.currentModel, prompt: finalPrompt,
                                                        showThink: self.showThink, images: self.promptImages)
                            } else {
                                debugPrint("❌ Unable to connect to the API server. Please verify the server address in Settings.")
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .task {
                    try? await self.initModelList()
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .navigationTitle("macLlama")
    }
}


//MARK: Internal functions
extension ChatInterfaceView {
    ///Send Chat to Ollama server
    private func sendChat(model: String, prompt: String, showThink: Bool, images: [NSImage]) async throws {
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
            
            self.history.append(.init(isUser: false, modelName: self.currentModel, message: ""))
            
            //Start stream from model
            Task {
                #if DEBUG
                debugPrint("Generation Started")
                #endif
                
                let stream = try await chatService.sendMessage(model: model, userInput: prompt, images: images, showThink: self.showThink, predict: self.predict, temperature: self.temperature)
                for await update in stream {
                    let outputText = update
                    self.history[self.history.count - 1].message = outputText
                }
                
                #if DEBUG
                debugPrint("Generation finished")
                #endif
                
                if let lastMessage = await chatService.messages.last {
                    await self.saveSwiftDataHistory(history: lastMessage)
                }
                
                //Save last response to history
                if let content = await chatService.allMessages().last?.content,
                   let think = await chatService.allMessages().last?.assistantThink {
                    self.history[self.history.count - 1].message = content
                    self.history[self.history.count - 1].assistantThink = think
                } else {
                    self.history[self.history.count - 1].message = "Oops! Something went wrong. Please try again."
                }
                
                //Reset state
                await MainActor.run {
                    self.isThinking = false
                    self.isAutoScrolling = false
                    self.autoScrollTask = nil
                }
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
    
    ///Save SwiftData history
    func saveSwiftDataHistory(history: APIChatMessage) async {
        let chatHistory: SwiftDataChatHistory = SwiftDataChatHistory(conversationId: self.conversationId,
                                                                     conversationDate: Date(),
                                                                     chatData: history)
        modelContext.insert(chatHistory)
        
        #if DEBUG
        debugPrint("Chat History Saved in id: \(Date().description(with: .current))")
        debugPrint("Chat History Saved by conversation id: \(self.conversationId.uuidString)")
        #endif
    }
}

//
//  ConversationChatView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/17/25.
//

import SwiftUI
import Combine

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
    
    //For debouncing (Save for later version)
//    @State private var cancellableSet = Set<AnyCancellable>()
//    @State private var timerPublisher: Timer.TimerPublisher? = nil
    
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
                } else {
                    //If model is not exists on Ollama server
                    Text("You haven't added any Ollama models yet.\nPlease open the Preference pane to add one.")
                }
                
                ScrollViewReader { proxy in
                    ScrollView {
                        ForEach(0..<self.history.count, id: \.self) { index in
                            LazyVStack {
                                if history[index].message != "" {
                                    ChatBubbleView(isThinking: self.$isThinking, chatData: $history[index])
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
                    .onChange(of: isThinking) { _, newValue in
                        let isAutoScroll = UserDefaults.standard.bool(forKey: "isAutoScrollEnabled")
                        if isAutoScroll && newValue == false {
                            withAnimation(.linear(duration: 2.0)) {
                                proxy.scrollTo(history.count - 1, anchor: .bottom)
                            }
                        }
                    }
//                    .onChange(of: history.count) { _, _ in
//                        let isAutoScroll = UserDefaults.standard.bool(forKey: "isAutoScrollEnabled")
//                        if isAutoScroll {
//                            autoScrollTask = Task {
//                                while !Task.isCancelled {
//                                    try? await Task.sleep(nanoseconds: 1_500_000_000)
//                                    
//                                    
//                                    
//                                    if !isAutoScrolling {
//                                        break
//                                    }
//                                }
//                            }
//                        }
//                    }
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
                        if let suffix = UserDefaults.standard.string(forKey: "promptSuffix") {
                            let promptWithSuffix: String = self.prompt + " \(suffix)"
                            try await self.sendChat(model: self.currentModel, prompt: promptWithSuffix, images: self.promptImages)
                        } else {
                            try await self.sendChat(model: self.currentModel, prompt: self.prompt, images: self.promptImages)
                        }
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
                #if DEBUG
                debugPrint("Generation Started")
                #endif
                
                //Prepare resource for debouncing (Saving for later update)
//                var count: Int = 0
//                self.timerPublisher = Timer.publish(every: 0.3, on: .main, in: .common)
//                self.timerPublisher?.autoconnect().sink { _ in
//                    count += 1
//                }.store(in: &self.cancellableSet)
                
                let stream = try await chatService.sendMessage(model: model, userInput: prompt, images: images)
                for await update in stream {
                    let outputText = update
                    self.history[self.history.count - 1].message = outputText
                    //Debouncing stream (Saving for later update)
//                    if count % 2 == 0 {
//                        let outputText = update
//                        self.history[self.history.count - 1].message = outputText
//                    }
                }
                
                //Cancel timer
                self.timerPublisher?.connect().cancel()
                self.timerPublisher = nil
                
                #if DEBUG
                debugPrint("Generation finished")
                #endif
                
                //Save last response to history
                if let content = await chatService.allMessages().last?.content {
                    self.history[self.history.count - 1].message = content
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

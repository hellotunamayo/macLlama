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
    @EnvironmentObject var serverStatus: ServerStatus
    
    //Model selector state
    @State private var currentModel: String = ""
    @State private var isModelLoading: Bool = false
    
    //Request state
    @State private var prompt: String = ""
    @State private var modelList: [OllamaModel] = []
    @State private var isThinking: Bool = false
    @State private var isFetchingWebSearch: Bool = false
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
    @State private var isSettingOn: Bool = false
    @State private var isWebSearchOn: Bool = false
    
    //Local prefix & suffix of prompt
    @State private var localPrefix: String = ""
    @State private var localSuffix: String = ""
    
    let chatService: OllamaChatService = OllamaChatService()
    let ollamaNetworkService: OllamaNetworkService = OllamaNetworkService()
    let ollamaProfilePicture: NSImage? = NSImage(named: "llama_gray")
    let viewModel: ChatInterfaceViewModel = ChatInterfaceViewModel()

    var body: some View {
        ZStack {
            //MARK: Background View(Llama Image)
            if !self.currentModel.isEmpty {
                ChatBackgroundView()
            }
            
            //MARK: Conversation view
            ZStack(alignment: .top) {
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
                                    isModelLoading: $isModelLoading, isSettingOn: $isSettingOn,
                                    ollamaNetworkService: self.ollamaNetworkService) {
                        Task {
                            try? await self.initModelList()
                        }
                    }
                    .zIndex(1)
                }
                
                VStack {
                    ScrollViewReader { proxy in
                        ScrollView {
                            ForEach(0..<self.history.count, id: \.self) { index in
                                VStack {
                                    if history[index].message != "" {
                                        ChatBubbleView(isThinking: self.$isThinking, chatData: $history[index])
                                            .padding(EdgeInsets(top: index == 0 ? Units.normalGap * 4 : Units.normalGap,
                                                                leading: Units.normalGap,
                                                                bottom: Units.normalGap, trailing: Units.normalGap))
                                            .id(index)
                                        
                                        if !history[index].isUser {
                                            setGotoTopButton(index: index, proxy: proxy)
                                                .disabled(isThinking ? true : false)
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
                                            thinkingView()
                                        } else {
                                            errorView()
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
                        ChatInputView(isThinking: $isThinking, isWebSearchEnabled: $isWebSearchOn, prompt: $prompt, images: $promptImages) {
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
            }
            .task {
                try? await self.initModelList()
            }
        }
        .frame(minWidth: Units.chatWindowWidth)
        .background(setBackgroundColor())
        .navigationSplitViewColumnWidth(ideal: Units.chatWindowWidth)
        .navigationTitle("macLlama")
        .sheet(isPresented: $isSettingOn) {
            ChatSettingsView(showThink: $showThink, localPrefix: $localPrefix, localSuffix: $localSuffix, predict: $predict, temperature: $temperature, isWebSerchOn: $isWebSearchOn)
        }
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
                
                var finalPrompt: String = ""
                
                //Get summrized information if web search capability is enabled
                if isWebSearchOn {
                    self.isFetchingWebSearch = true
                    if let summary = await self.viewModel.getWebResponse(from: prompt) {
                        let searchedPrompt = """
                        You are a helpful AI assistant dedicated to answering questions. Combine the information provided below with your existing knowledge to provide context and clarify details, but *all factual claims* must be directly supported by the provided text, meaning they must be either a direct quote or a paraphrase that accurately reflects the text’s meaning. Always cite the source (e.g., paragraph number, section title) whenever possible.  If the provided text contains conflicting information, acknowledge the conflict and present both perspectives without taking a definitive stance.  You will be asked factual and explanatory questions based on the provided text. Do *not* speculate, offer opinions, or generate information not found within the provided text.
                    
                        If the question cannot be answered using the provided text, please respond with: "I'm sorry, the answer to this question isn't available in the provided information."
                    
                        When answering, please cite the source and provide the URL for reference.  Format your answers and citations like this:
                    
                        Answer derived *directly* from the provided text
                    
                        Source: [A brief description of the provided text, e.g., "A summary from the World Wildlife Fund about polar bear populations."]
                        Reference URL: \(summary.1)  (This URL is for reference and does not need to be displayed in the answer.)
                    
                        Here is the information you are to use: \(summary.0)
                    
                        The question you will answer is: \(prompt)
                    """
                        finalPrompt = searchedPrompt
                    } else {
                        finalPrompt = prompt
                    }
                    
                    self.isFetchingWebSearch = false
                } else {
                    finalPrompt = prompt
                }
                
                let stream = try await chatService.sendMessage(model: model, userInput: finalPrompt, images: images, showThink: self.showThink, predict: self.predict, temperature: self.temperature)
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
    private func saveSwiftDataHistory(history: APIChatMessage) async {
        let chatHistory: SwiftDataChatHistory = SwiftDataChatHistory(conversationId: self.conversationId,
                                                                     conversationDate: Date(),
                                                                     chatData: history)
        modelContext.insert(chatHistory)
        
        #if DEBUG
        debugPrint("Chat History Saved in id: \(Date().description(with: .current))")
        debugPrint("Chat History Saved by conversation id: \(self.conversationId.uuidString)")
        #endif
    }
    
    private func setBackgroundColor() -> some View {
        if #available(macOS 26.0, *) {
            return Color.clear
        } else {
            return Color(nsColor: .windowBackgroundColor)
        }
    }
}

//MARK: Viewbuilders
extension ChatInterfaceView {
    @ViewBuilder
    private func setGotoTopButton(index: Int, proxy: ScrollViewProxy) -> some View {
        if #available(macOS 26.0, *) {
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
            .glassEffect()
        } else {
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
            .buttonStyle(.bordered)
        }
    }
    
    @ViewBuilder
    func errorView() -> some View {
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
    
    @ViewBuilder
    func thinkingView() -> some View {
        VStack {
            ProgressView()
                .frame(width: 14, height: 14)
                .padding(.bottom)
            
            Text(self.isFetchingWebSearch ? "Fetching web search results..." : "Ollama is Thinking...")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

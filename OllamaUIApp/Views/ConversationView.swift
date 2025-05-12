//
//  ContentView.swift
//  OllamaUIApp
//
//  Created by Minyoung Yoo on 5/7/25.
//

import SwiftUI
import AppKit
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
    @FocusState private var promptFocusState: Bool
    
    @State private var prompt: String = ""
    @State private var chatHistory: [Chat] = []
    @State private var modelList: [OllamaModel] = []
    @State private var currentModel: String = ""
    @State private var isThinking: Bool = false
    @State private var scrollToIndex: Int = 0
    @State private var userProfileImage: NSImage?
    @State private var ollamaWarningBouncingYOffset: CGFloat = 0
    @State internal var ollamaNetworkService: OllamaNetworkService?

    let ollamaProfilePicture: NSImage? = NSImage(named: "llama_gray")
    
    var body: some View {
        ZStack {
            //MARK: Background View(Llama Image)
            if !self.currentModel.isEmpty {
                VStack {
                    Image("llama_gray")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: Units.appFrameMinHeight / 2, maxHeight: Units.appFrameMinHeight / 2)
                        .offset(y: Units.appFrameMinHeight / 20 * -1)
                        .opacity(self.colorScheme == .dark ? 0.06 : 0.07)
                }
            }
            
            //MARK: Conversation view
            VStack {
                if !self.modelList.isEmpty {
                    Picker("Select a model", selection: $currentModel) {
                        ForEach(modelList, id: \.self) { model in
                            Text(model.name)
                                .foregroundStyle(.primary)
                                .tag(model.name)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .onChange(of: currentModel) { oldValue, newValue in
                        Task {
                            await self.ollamaNetworkService?.changeModel(model: newValue)
                        }
                    }
                }
                
                //MARK: Chat Scroll View
                ScrollViewReader { proxy in
                    ScrollView {
                        ForEach(0..<self.chatHistory.count, id: \.self) { index in
                            Divider()
                                .foregroundStyle(Color(nsColor: .systemGray))
                                .opacity(self.colorScheme == .dark ? 1.0 : 0.9)
                            
                            ChatBubbleView(chatData: chatHistory[index])
                                .padding()
                                .id(index)
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
                    HStack {
                        //Input text field
                        VStack {
                            TextEditor(text: $prompt)
                                .font(.title2)
                                .frame(height: 34)
                                .clipShape(.rect(cornerRadius: 8))
                                .focused($promptFocusState)
                                .onKeyPress { keypress in
                                    if keypress.key == .return {
                                        Task {
                                            try await self.sendMessage()
                                        }
                                        return .handled
                                    } else {
                                        return .ignored
                                    }
                                }
                        }
                        .frame(height: 60)
                        .onAppear {
                            self.promptFocusState = true
                        }
                        
                        //Send button
                        Button {
                            if self.isThinking {
                                print("One message at a time, please!")
                            } else {
                                Task {
                                    try await self.sendMessage()
                                }
                            }
                        } label: {
                            if self.isThinking {
                                ThinkingView()
                            } else {
                                Label("Send", systemImage: "paperplane.fill")
                                    .font(.title2)
                                    .padding(.horizontal, Units.normalGap)
                                    .padding(.vertical, Units.normalGap / 3.5)
                                    .frame(minWidth: 100)
                            }
                        }
                        .tint(self.isThinking ? .gray : .accent)
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(height: 60)
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                if self.modelList.isEmpty {
                    VStack {
                        Image("ollama_warning")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: Units.appFrameMinWidth / 3,
                                   maxHeight: Units.appFrameMinHeight / 4)
                            .foregroundStyle(.yellow)
                            .background(Color(nsColor: NSColor.windowBackgroundColor))
                            .clipShape(Circle())
                            .shadow(color:.black.opacity(0.2), radius: 3)
                            .padding(.bottom, -10)
                            .offset(y: ollamaWarningBouncingYOffset)
                            .animation(.bouncy(duration: 1.5, extraBounce: 1), value: ollamaWarningBouncingYOffset)
                            .onAppear {
                                self.ollamaWarningBouncingYOffset = 3
                            }
                        
                        Text("Your Ollama server may down")
                            .font(.largeTitle)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            Task {
                                guard let _ = await ShellService.runShellScript("ollama serve") else { return }
                                
                                //TODO: Replace this temporary solution!
                                sleep(1)
                                
                                ollamaNetworkService = OllamaNetworkService(stream: false)
                                try await self.initModelList()
                            }
                        } label: {
                            Label("Try to turn on Ollama Server", systemImage: "power")
                                .padding(.trailing, Units.normalGap / 4)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.top, Units.normalGap / 2)
                        
                        Divider()
                            .frame(maxWidth: 30)
                            .padding(.vertical, Units.normalGap)
                        
                        Text("If the problem persists, please check\nthat the Ollama server is installed on your system")
                            .foregroundStyle(Color.gray)
                            .lineSpacing(Units.normalGap / 5)
                            .multilineTextAlignment(.center)
                            .font(.subheadline)
                    }
                    .padding(.top, Units.normalGap * -3)
                }
            }
        }
    }
    
    //MARK: Internal functions
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

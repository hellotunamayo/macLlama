//
//  ChatBubbleView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/9/25.
//

import SwiftUI
import MarkdownUI

struct ChatBubbleView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("chatFontSize") var chatFontSize: Int = AppSettings.chatFontSize
    @AppStorage("markdownTheme") var markdownTheme: String = AppSettings.markdownTheme
    @Binding var isThinking: Bool
    @State private var messageAnimationFactor: CGFloat = 0.0
    @State private var messageAnimated: Bool = false
    @State private var isMarkdownEnabled: Bool = false
    @State private var chatMessage: String = ""
    @State private var showAssistantThink: Bool = false
    
    var assistantThinkContext: String? {
        if let text = self.chatData.assistantThink {
            return text
        } else {
            return nil
        }
    }
    
    @Binding var chatData: LocalChatHistory
    
    var body: some View {
        HStack(alignment: .top) {
            //MARK: Ollama profile picture
            if !chatData.isUser {
                VStack(alignment: .center) {
                    Image(nsImage: NSImage(named: "ollama_profile")!)
                        .resizable()
                        .frame(width: 50, height: 50, alignment: .center)
                        .backgroundStyle(.white)
                        .clipShape(.circle)
                        .padding(.trailing, Units.normalGap / 2)
                        .shadow(radius: 1)
                }
            }
            
            //MARK: Ollama Answer
            VStack(alignment: chatData.isUser ? .trailing : .leading) {
                HStack {
                    if !chatData.isUser { //If message is Ollama answer
                        VStack {
                            Text(chatData.modelName)
                                .padding(.horizontal, Units.normalGap / 1.5)
                                .padding(.vertical, Units.normalGap / 3)
                                .lineLimit(1)
                                .foregroundStyle(.white)
                        }
                        .background(Color(nsColor: .black).opacity(0.7))
                        .clipShape(Capsule())
                        
                        Button {
                            isMarkdownEnabled.toggle()
                        } label: {
                            HStack {
                                Group {
                                    Image("markdown-symbol")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 15)
                                    
                                    Image(systemName: isMarkdownEnabled ? "circle" : "xmark")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 13, height: 13)
                                }
                            }
                            .padding(.horizontal, Units.normalGap / 1.5)
                            .padding(.vertical, Units.normalGap / 3)
                            .foregroundStyle(.white)
                        }
                        .controlSize(.small)
                        .buttonStyle(.borderless)
                        .background(isMarkdownEnabled ? Color("maridownIndicateGreen").opacity(0.7) : Color.black.opacity(0.7))
                        .clipShape(Capsule())
                        .opacity(isThinking ? 0.3 : 1)
                        .disabled(isThinking ? true : false)
                        .help("Enable Markdown rendering")
                        
                        Spacer()
                    }
                    
                    VStack {
                        Label("Copied to clipboard", systemImage: "checkmark.circle")
                            .font(.system(size: 12))
                            .padding(.horizontal, Units.normalGap / 1.3)
                            .padding(.vertical, Units.normalGap / 4)
                            .background(.green.opacity(colorScheme == .dark ? 0.5 : 0.3))
                            .clipShape(Capsule())
                            .lineLimit(1)
                            .opacity(messageAnimationFactor)
                            .offset(x: messageAnimated ? 0 : messageAnimationFactor + 5)
                    }
                    .padding(.trailing, Units.normalGap / 4)
                    
                    Button {
                        copyChatToClipboard()
                    } label: {
                        Image(systemName: "document.on.document")
                            .padding(.horizontal, Units.normalGap / 4)
                            .padding(.vertical, Units.normalGap / 6)
                    }
                    .tint(.gray)
                    .controlSize(.small)
                    .buttonStyle(.bordered)
                    .help("Copy this text to clipboard")
                }
                
                VStack {
                    if let thinkContext = self.assistantThinkContext, !thinkContext.isEmpty {
                        VStack(alignment: .leading) {
                            Button {
                                withAnimation {
                                    showAssistantThink.toggle()
                                }
                            } label: {
                                Label(showAssistantThink ? "Hide Assistant Thinking" : "Show Assistant Thinking",
                                      systemImage: "brain")
                                .frame(minWidth: Units.chatBubbleMinWidth, maxWidth: .infinity, alignment: .leading)
                                .padding(EdgeInsets(top: Units.normalGap, leading: Units.normalGap / 4,
                                                    bottom: Units.normalGap, trailing: 0))
                            }
                            .controlSize(.small)
                            .buttonStyle(.borderless)
                            .clipShape(Capsule())
                            .disabled(isThinking ? true : false)
                            .help("Show or hide assistant thinking")
                        }
                    }
                    
                    if let think = self.chatData.assistantThink, showAssistantThink == true {
                        VStack {
                            Text("\(chatData.modelName)'s think")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .padding(.bottom, 0)
                            
                            TextEditor(text: .constant(think))
                                .font(.body)
                                .foregroundStyle(Color.secondary)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
//                                .frame(minHeight: 200, idealHeight: 200, maxHeight: 600)
                                .scrollContentBackground(.hidden)
                                .padding()
                        }
                        .background(
                            RoundedRectangle(cornerRadius: Units.normalGap / 2)
                                .fill(Color.black)
                        )
                    }
                    
                    if isMarkdownEnabled && !isThinking {
                        Markdown {
                            MarkdownContent(chatMessage)
                        }
                        .markdownTextStyle(\.code) {
                            FontFamilyVariant(.monospaced)
                        }
                        .markdownTextStyle(\.text) {
                            BackgroundColor(nil)
                            FontSize(CGFloat(chatFontSize))
                        }
                        .textSelection(.enabled)
                        .markdownTheme(
                            MarkdownTheme.getTheme(themeName: markdownTheme)
                        )
                        .padding(.top, Units.normalGap / 4)
                    } else {
                        if !chatData.isUser {
                            TextEditor(text: $chatMessage)
                                .font(.system(size: CGFloat(chatFontSize)))
                                .lineSpacing(CGFloat(chatFontSize / 3))
                                .scrollDisabled(true)
                                .textSelection(.enabled)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 50, alignment: .leading)
                                .padding(.top, Units.normalGap / 4)
                        } else {
                            Text(chatData.message)
                                .font(.system(size: CGFloat(chatFontSize)))
                                .lineSpacing(CGFloat(chatFontSize / 3))
                                .textSelection(.enabled)
                                .frame(alignment: .trailing)
                        }
                    }
                }
                .padding(.horizontal, chatData.isUser ? Units.normalGap * 1.3 : 0)
                .padding(.vertical, chatData.isUser ? Units.normalGap / 1.5 : 0)
                .background(chatData.isUser ? Color("UserChatBubbleColor") : .clear)
                .clipShape(chatData.isUser ? RoundedRectangle(cornerRadius: 8) : RoundedRectangle(cornerRadius: 0))
                .frame(maxWidth: .infinity, alignment: chatData.isUser ? .trailing : .leading)
                .onChange(of: self.chatData.message) { _, newValue in
                    self.chatMessage = newValue
                }
            }
            
            //Remains for future features (User's chat avatar)
//            if chatData.isUser {
//                Circle()
//                    .fill(Color.gray)
//                    .overlay{
//                        Text("You")
//                            .frame(width: 50, height: 50)
//                            .clipShape(Circle())
//                    }
//                    .frame(width: 50, height: 50)
//            }
        }
    }
}

extension ChatBubbleView {
    private func copyChatToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(chatData.message, forType: .string)
        animateCopiedButton()
    }
    
    private func animateCopiedButton() {
        withAnimation {
            messageAnimated = true
            messageAnimationFactor = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                messageAnimated = false
                messageAnimationFactor = 0.0
            }
        }
    }
    
    ///EXPREIMENTAL : Convert string to LocalizedString for rendering Markdown
    private func convertCodeBlock(_ input: String) -> String {
        let regex = /```(?<name>([0-9A-Za-z ]*))(\r|\n)(?<content>(([^```])*))```/
        var resultString = input
        
        for match in input.matches(of: regex).reversed() {
            let content = String(match.content)
            let newCodeBlock = content.split(separator: "\n").map({"`\($0)`"}).joined(separator: "\n")
            resultString.replaceSubrange(match.range, with: newCodeBlock)
        }
        
        return resultString
    }
}

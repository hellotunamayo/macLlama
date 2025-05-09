//
//  ChatBubbleView.swift
//  OllamaUIApp
//
//  Created by Minyoung Yoo on 5/9/25.
//

import SwiftUI
import MarkdownUI

struct ChatBubbleView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var messageAnimationFactor: CGFloat = 0.0
    @State private var messageAnimated: Bool = false
    let chatData: Chat
    
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
            VStack(alignment: .leading) {
                if !chatData.isUser {
                    HStack {
                        VStack {
                            Text(chatData.modelName)
                                .padding(.horizontal, Units.normalGap / 1.5)
                                .padding(.vertical, Units.normalGap / 3)
                                .foregroundStyle(.white)
                        }
                        .background(Color(nsColor: .black).opacity(0.7))
                        .clipShape(Capsule())
                        
                        Spacer()
                        
                        VStack {
                            Label("Copied to clipboard", systemImage: "checkmark.circle")
                                .font(.system(size: 12))
                                .padding(.horizontal, Units.normalGap / 1.3)
                                .padding(.vertical, Units.normalGap / 4)
                                .background(.green.opacity(colorScheme == .dark ? 0.5 : 0.3))
                                .clipShape(Capsule())
                                .opacity(messageAnimationFactor)
                                .offset(x: messageAnimated ? 0 : messageAnimationFactor + 5)
                        }
                        .padding(.trailing, Units.normalGap / 4)
                        
                        Button {
                            if !chatData.isUser {
                                copyChatToClipboard()
                            }
                        } label: {
                            Image(systemName: "document.on.document")
                                .padding(.horizontal, Units.normalGap / 4)
                                .padding(.vertical, Units.normalGap / 6)
                        }
                        .tint(.gray)
                        .controlSize(.small)
                        .buttonStyle(.bordered)
                    }
                }
                
                Markdown {
                    MarkdownContent(chatData.message)
                }
                .markdownTextStyle(\.code) {
                    FontFamilyVariant(.monospaced)
                }
                .markdownTextStyle(\.text) {
                    BackgroundColor(nil)
                    FontSize(18)
                }
                .markdownTheme(.gitHub)
            }
            .padding(.horizontal, chatData.isUser ? Units.normalGap * 1.3 : 0)
            .padding(.vertical, chatData.isUser ? Units.normalGap / 1.5 : 0)
            .background(chatData.isUser ? .black.opacity(0.15) : .clear)
            .clipShape(chatData.isUser ? RoundedRectangle(cornerRadius: 8) : RoundedRectangle(cornerRadius: 0))
            .frame(maxWidth: .infinity, alignment: chatData.isUser ? .trailing : .leading)
        }
    }
    
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
}

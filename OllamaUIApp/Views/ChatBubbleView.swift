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
    
    @State private var messageOpacity: CGFloat = 0.0
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
                    
                    if !chatData.isUser {
                        VStack {
                            Text("Copied")
                                .padding(.horizontal, Units.normalGap / 1.5)
                                .padding(.vertical, Units.normalGap / 2.5)
                                .background(.green.opacity(colorScheme == .dark ? 0.5 : 0.3))
                                .clipShape(Capsule())
                                .opacity(messageOpacity)
                        }
                        .padding(.trailing, Units.normalGap / 2)
                    }
                }
            }
            
            //MARK: Ollama Answer
            VStack {
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
            .onHover { inside in
                if !chatData.isUser && inside {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            .onTapGesture {
                if !chatData.isUser {
                    messageOpacity = 0.0
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(chatData.message, forType: .string)
                    withAnimation(.default) {
                        messageOpacity = 1.0
                    }
                    
                    print("Message is copied to clipboard.")
                }
            }
        }
    }
}

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
    @State private var messageAnimationFactor: CGFloat = 0.0
    @State private var messageAnimated: Bool = false
    
    let chatData: (isUser: Bool, modelName: String, message: String)
    
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
                    if !chatData.isUser {
                        VStack {
                            Text(chatData.modelName)
                                .padding(.horizontal, Units.normalGap / 1.5)
                                .padding(.vertical, Units.normalGap / 3)
                                .foregroundStyle(.white)
                        }
                        .background(Color(nsColor: .black).opacity(0.7))
                        .clipShape(Capsule())
                        
                        Spacer()
                    }
                    
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
                        copyChatToClipboard()
                    } label: {
                        Image(systemName: "document.on.document")
                            .padding(.horizontal, Units.normalGap / 4)
                            .padding(.vertical, Units.normalGap / 6)
                    }
                    .tint(.gray)
                    .controlSize(.small)
                    .buttonStyle(.bordered)
                }
                
                VStack {
                    #if DEBUG
                    Text(.init(convertCodeBlock(chatData.message)))
                        .font(.system(size: CGFloat(chatFontSize)))
                        .lineSpacing(CGFloat(chatFontSize / 3))
                        .textSelection(.enabled)
                        .frame(alignment: chatData.isUser ? .trailing : .leading)
                    #else
                    Text(chatData.message)
                        .font(.system(size: CGFloat(chatFontSize)))
                        .lineSpacing(CGFloat(chatFontSize / 3))
                        .textSelection(.enabled)
                        .frame(alignment: chatData.isUser ? .trailing : .leading)
                    #endif
                        
                    //Temporary disable MarkdownUI for rendering performance issue.
//                    Markdown {
//                        MarkdownContent(chatData.message)
//                    }
//                    .markdownTextStyle(\.code) {
//                        FontFamilyVariant(.monospaced)
//                    }
//                    .markdownTextStyle(\.text) {
//                        BackgroundColor(nil)
//                        FontSize(18)
//                    }
//                    .markdownTheme(.gitHub)
                }
                .padding(.horizontal, chatData.isUser ? Units.normalGap * 1.3 : 0)
                .padding(.vertical, chatData.isUser ? Units.normalGap / 1.5 : 0)
                .background(chatData.isUser ? .black.opacity(0.15) : .clear)
                .clipShape(chatData.isUser ? RoundedRectangle(cornerRadius: 8) : RoundedRectangle(cornerRadius: 0))
                .frame(maxWidth: .infinity, alignment: chatData.isUser ? .trailing : .leading)
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

//
//  ChatHistoryDetailView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/29/25.
//

import SwiftUI
import SwiftData
import MarkdownUI

struct ChatHistoryDetailView: View {
    @AppStorage("chatFontSize") var chatFontSize: Int = AppSettings.chatFontSize
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) var modelContext
    @Query(sort: \ChatHistory.createdDate, order: .forward) private var history: [ChatHistory] = []
    
    let conversationId: String
    private var conversations: [ChatHistory] {
        let filteredHistory = history.filter { $0.conversationId.uuidString == self.conversationId }
        return filteredHistory
    }
    private var isUserChat: (ChatHistory) -> Bool {
        { history in
            return history.chatData.role == "user"
        }
    }
    private var conversationDate: String {
        if let date = history.first?.createdDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM d, yyyy, hh:mm:ss a"
            let formattedString = dateFormatter.string(from: date)
            return formattedString
        } else {
            return "Unknown Date"
        }
    }
    
    var body: some View {
        ScrollView {
            ForEach(conversations) { conversation in
                VStack {
                    if isUserChat(conversation) {
                        Text(conversation.chatData.content)
                            .font(.system(size: CGFloat(chatFontSize)))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .textSelection(.enabled)
                            .padding()
                        .clipShape(RoundedRectangle(cornerRadius: Units.normalGap / 2))
                        .padding()
                    } else {
                        Markdown {
                            MarkdownContent(conversation.chatData.content)
                        }
                        .markdownTextStyle(\.code) {
                            FontFamilyVariant(.monospaced)
                        }
                        .markdownTextStyle(\.text) {
                            BackgroundColor(nil)
                            FontSize(CGFloat(chatFontSize))
                        }
                        .textSelection(.enabled)
                        .markdownTheme(.docC)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                }
                .background(isUserChat(conversation) ? Color("UserChatBubbleColor") : .clear)
            }
        }
        .navigationTitle("Chat in \(conversationDate)(\(conversationId))")
        .listStyle(.plain)
        .listSectionSeparator(.hidden)
    }
}

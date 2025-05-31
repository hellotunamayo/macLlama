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
    @AppStorage("markdownTheme") var markdownTheme: String = AppSettings.markdownTheme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) var modelContext
    @Query(sort: \SwiftDataChatHistory.createdDate, order: .forward) private var history: [SwiftDataChatHistory] = []
    
    @State private var conversations: [SwiftDataChatHistory] = []
    
    let conversationId: String
    
    private var isUserChat: (SwiftDataChatHistory) -> Bool {
        { history in
            return history.chatData.role == "user"
        }
    }
    private var conversationDate: (Date) -> String {
        { date in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM d, yyyy, hh:mm:ss a"
            let formattedString = dateFormatter.string(from: date)
            return formattedString
        }
    }
            
    var body: some View {
        ScrollView {
            ForEach(conversations) { conversation in
                VStack {
                    Text(conversationDate(conversation.conversationDate))
                        .font(.footnote)
                        .padding(.top, Units.normalGap / 2)
                        .opacity(0.5)
                    
                    if isUserChat(conversation) {
                        HStack(alignment: .top) {
                            Text(conversation.chatData.content)
                                .font(.system(size: CGFloat(chatFontSize)))
                                .lineSpacing(Units.normalGap / 3)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .textSelection(.enabled)
                                .padding()
                                .clipShape(RoundedRectangle(cornerRadius: Units.normalGap / 2))
                            
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: Units.normalGap * 3, height: Units.normalGap * 3)
                                .overlay {
                                    Text("You")
                                        .foregroundStyle(Color.primary)
                                }
                                .padding(.trailing)
                                .padding(.bottom)
                        }
                        .padding(.vertical)
                    } else {
                        HStack(alignment: .top) {
                            Image("ollama_profile")
                                .resizable()
                                .frame(width: Units.normalGap * 3, height: Units.normalGap * 3)
                                .clipShape(Circle())
                                .padding(.top)
                                .padding(.leading)
                            
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
                            .markdownTheme(
                                MarkdownTheme.getTheme(themeName: markdownTheme)
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                        }
                        .padding(.vertical)
                    }
                }
                .background(isUserChat(conversation) ? Color("UserChatBubbleColor") : .clear)
            }
        }
        .listStyle(.plain)
        .listSectionSeparator(.hidden)
        .task {
            await fetchFilteredHistory()
        }
        .onChange(of: self.conversationId) { _, _ in
            Task {
                await fetchFilteredHistory()
            }
        }
    }
    
    func fetchFilteredHistory() async {
        self.conversations = []
        let filteredHistory = self.history.filter { $0.conversationId.uuidString == self.conversationId }
        self.conversations = filteredHistory
    }
}

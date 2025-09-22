//
//  ContentView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/7/25.
//

import SwiftUI
import SwiftData

struct ConversationWindowView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var serverStatus: ServerStatus
    @Query(sort: \SwiftDataChatHistory.createdDate, order: .forward) private var chatHistory: [SwiftDataChatHistory]
    
    var history: [LocalChatHistory] {
        fetchHistory()
    }
    
    let conversationId: String?
    var conversationUUID: UUID {
        if let idString = conversationId {
            return UUID(uuidString: idString) ?? UUID()
        } else {
            return UUID()
        }
    }
    
    var body: some View {
        if serverStatus.isOnline {
            ChatInterfaceView(history: history, conversationId: conversationUUID)
                .environmentObject(serverStatus)
        } else {
            StartServerView()
                .environmentObject(serverStatus)
                .padding(.top, Units.normalGap * -3)
        }
    }
    
    ///Get conversation from history
    private func fetchHistory() -> [LocalChatHistory] {
        var conversationHistory: [LocalChatHistory] = []
        guard let conversationId = self.conversationId else {
            return conversationHistory
        }
        let result = chatHistory.filter({$0.conversationId.uuidString == conversationId}).sorted(by: { $0.conversationDate < $1.conversationDate })
        
        
        if result.count == 0 {
            return conversationHistory
        }
        
        result.forEach { history in
            let isUser = history.chatData.role == "user" ? true : false
            let message = history.chatData.content
            let history: LocalChatHistory = .init(isUser: isUser, modelName: "macLlama History", message: message)
            conversationHistory.append(history)
        }
        
        return conversationHistory
    }
}

#Preview {
    ConversationWindowView(conversationId: nil)
        .modelContainer(for: Item.self, inMemory: true)
}

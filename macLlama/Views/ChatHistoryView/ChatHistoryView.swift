//
//  ChatHistoryView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/29/25.
//

import SwiftUI
import SwiftData

struct ChatHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatHistory.createdDate, order: .reverse) private var chatHistory: [ChatHistory]
    @Query(sort: \SwiftDataChatHistory.createdDate, order: .reverse) private var chatHistory: [SwiftDataChatHistory]
    
    @State private var selectedId: String = ""
    @State private var isAlertPresented: Bool = false
    
    var formattedDateString: (Date) -> String {
        { input in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM d, yyyy, hh:mm:ss a"
            let formattedString = dateFormatter.string(from: input)
            return formattedString
        }
    }
    
    var distinctConversationIDs: [String] {
        var list: [String] = []
        chatHistory.forEach { history in
            if !list.contains(history.conversationId.uuidString) {
                list.append(history.conversationId.uuidString)
            }
        }
        return list
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedId) {
                ForEach(distinctConversationIDs, id: \.self) { element in
                    Text(element)
                        .tag(element)
                }
            }
            .listStyle(.sidebar)
        } detail: {
            ChatHistoryDetailView(conversationId: selectedId)
                .frame(minWidth: 600)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if !selectedId.isEmpty {
                    Button {
                        isAlertPresented = true
                    } label: {
                        Label("Delete This History", systemImage: "trash")
                    }
                    .alert("Delete this history.\nThis action cannot be undone.", isPresented: $isAlertPresented, actions: {
                        Button(role: .destructive) {
                            try? deleteChatHistory(conversationID: selectedId)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    })
                }
            }
        }
    }
    
    private func deleteChatHistory(conversationID id: String) throws {
        do {
            guard let uuid = UUID(uuidString: id) else { throw NSError(domain: "", code: 0, userInfo: nil) }
            try modelContext.delete(model: ChatHistory.self, where: #Predicate{ $0.conversationId == uuid })
            try modelContext.delete(model: SwiftDataChatHistory.self, where: #Predicate{ $0.conversationId == uuid })
        } catch {
            debugPrint("Error deleting chat history: \(error)")
        }
    }
}

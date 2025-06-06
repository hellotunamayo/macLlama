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
        var list: Set<String> = []
        chatHistory.forEach { history in
            let conversationId = history.conversationId.uuidString
            list.insert(conversationId)
        }
        let resultArray = Array(list)
        return resultArray
    }
    
    var getInitialTime: [String] {
        var list: [String] = []
        let distinctConversatinIDs = self.distinctConversationIDs
        for uuidString in distinctConversatinIDs {
            if let filtered = chatHistory.filter({ $0.conversationId.uuidString == uuidString }).last {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM d, yyyy, hh:mm:ss a"
                let formattedDateString = formatter.string(from: filtered.createdDate)
                list.append(formattedDateString)
            }
        }
        return list.sorted().reversed()
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedId) {
                ForEach(distinctConversationIDs.indices, id: \.self) { index in
                    Text(getInitialTime[index])
                        .tag(distinctConversationIDs[index])
                }
            }
            .listStyle(.sidebar)
        } detail: {
            if distinctConversationIDs.isEmpty {
                Image("ollama_warning")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 140, height: 140)
                    .padding()
                    .opacity(0.8)
                Text("No Chat History Found")
                    .font(.title)
                    .foregroundStyle(.secondary)
            } else {
                ChatHistoryDetailView(conversationId: selectedId)
                    .frame(minWidth: 600)
            }
        }
        .toolbar {
            ToolbarItemGroup {
                if !selectedId.isEmpty {
                    Button {
                        try? deleteChatHistory(conversationID: selectedId)
                    } label: {
                        Text("Delete This History")
                            .padding(.horizontal, Units.normalGap / 3)
                    }
                }
                
                if !distinctConversationIDs.isEmpty {
                    Button(role: .destructive) {
                        self.isAlertPresented = true
                    } label: {
                        Text("Delete All History")
                            .padding(.horizontal, Units.normalGap / 3)
                            .foregroundStyle(.red)
                    }
                    .alert(isPresented: $isAlertPresented) {
                        Alert(title: Text("Delete All Chat History"), message: Text("This action cannot be undone."),
                              primaryButton: .cancel(), secondaryButton: .destructive(Text("Delete"), action: {
                            do {
                                try modelContext.delete(model: SwiftDataChatHistory.self)
                                self.selectedId = ""
                            } catch {
                                debugPrint("Failed to clear all history data.")
                            }
                        }))
                    }
                }
            }
        }
    }
    
    private func deleteChatHistory(conversationID id: String) throws {
        do {
            guard let uuid = UUID(uuidString: id) else { throw NSError(domain: "", code: 0, userInfo: nil) }
            try modelContext.delete(model: SwiftDataChatHistory.self, where: #Predicate{ $0.conversationId == uuid })
            self.selectedId = ""
        } catch {
            debugPrint("Error deleting chat history: \(error)")
        }
    }
}

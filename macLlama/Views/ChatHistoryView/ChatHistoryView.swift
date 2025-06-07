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
    @State private var distinctConversationDateList: [Date] = []
    @State private var distinctConversationIDs: [String] = []
    
    var formattedDateString: (Date) -> String {
        { input in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd, yyyy h:mm a"
            let formattedString = dateFormatter.string(from: input)
            return formattedString
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedId) {
                ForEach(distinctConversationDateList.indices, id: \.self) { index in
                    Text(formattedDateString(distinctConversationDateList[index]))
                        .tag(distinctConversationIDs[index])
                }
            }
            .listStyle(.sidebar)
            .task {
                self.distinctConversationIDs = await self.getDistictHistoryID()
                await self.sortDistictHistoryByDate(distinctHistoryId: distinctConversationIDs)
            }
        } detail: {
            if distinctConversationDateList.isEmpty {
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
                
                if !distinctConversationDateList.isEmpty {
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
    
    private func getDistictHistoryID() async -> [String] {
        var chatHistoryId: Set<String> = []
        self.chatHistory.forEach { history in
            let conversationId = history.conversationId.uuidString
            chatHistoryId.insert(conversationId)
        }
        let distinctHistoryIdSet = Array(chatHistoryId)
        return distinctHistoryIdSet
    }
    
    private func sortDistictHistoryByDate(distinctHistoryId: [String]) async {
        //Sort distinct value by initiated date
        var dateSortingConversation: [(date: Date, idString: String)] = []
        for uuidString in distinctHistoryId {
            if let filtered = chatHistory.filter({ $0.conversationId.uuidString == uuidString }).last {
                dateSortingConversation.append((filtered.conversationDate, filtered.conversationId.uuidString))
            }
        }
        
        //Reset state values
        self.distinctConversationDateList = []
        self.distinctConversationIDs = []
        
        //Sort tuple array by conversation date and append
        dateSortingConversation.sorted { $0 > $1 }.forEach { item in
            self.distinctConversationDateList.append(item.date)
            self.distinctConversationIDs.append(item.idString)
        }
    }
}

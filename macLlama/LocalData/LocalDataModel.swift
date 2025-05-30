//
//  LocalDataModel.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/29/25.
//

import Foundation
import SwiftData

@Model
final class SwiftDataChatHistory: Identifiable {
    @Attribute(.unique) var id: UUID
    var conversationId: UUID
    var conversationDate: Date
    var createdDate: Date
    var chatData: APIChatMessage
    
    init(id: UUID = .init(), conversationId: UUID, conversationDate: Date, createdDate: Date = Date(), chatData: APIChatMessage) {
        self.id = id
        self.conversationId = conversationId
        self.conversationDate = conversationDate
        self.createdDate = createdDate
        self.chatData = chatData
    }
}

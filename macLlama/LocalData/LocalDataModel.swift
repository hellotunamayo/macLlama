//
//  LocalDataModel.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/29/25.
//

import Foundation
import SwiftData

@Model
final class ChatHistory: Identifiable {
    @Attribute(.unique) var id: UUID
    var conversationId: UUID
    var conversationDate: Date
    var createdDate: Date
    var chatData: ChatMessage
    
    init(id: UUID = .init(), conversationId: UUID, conversationDate: Date, createdDate: Date = Date(), chatData: ChatMessage) {
        self.id = id
        self.conversationId = conversationId
        self.conversationDate = conversationDate
        self.createdDate = createdDate
        self.chatData = chatData
    }
}

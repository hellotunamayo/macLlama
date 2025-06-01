//
//  ContentView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/7/25.
//

import SwiftUI
import SwiftData

struct ConversationView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var serverStatus: ServerStatus
    
    var body: some View {
        if serverStatus.isOnline {
            ConversationChatView()
                .environmentObject(serverStatus)
        } else {
            StartServerView()
                .environmentObject(serverStatus)
                .padding(.top, Units.normalGap * -3)
        }
    }
}


#Preview {
    ConversationView()
        .modelContainer(for: Item.self, inMemory: true)
}

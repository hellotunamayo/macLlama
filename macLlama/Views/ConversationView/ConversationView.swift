//
//  ContentView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/7/25.
//

import SwiftUI
import SwiftData
import MarkdownUI

struct ConversationView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var serverStatus: ServerStatus
    
    var body: some View {
        if serverStatus.indicator == false {
            StartServerView() {
                let _ = await ShellService.runShellScript("ollama serve")
                try await Task.sleep(for: .seconds(1))
                try await self.serverStatus.updateServerStatus()
            }
            .padding(.top, Units.normalGap * -3)
        } else {
            ConversationChatView()
                .environmentObject(serverStatus)
        }
    }
}


#Preview {
    ConversationView()
        .modelContainer(for: Item.self, inMemory: true)
}

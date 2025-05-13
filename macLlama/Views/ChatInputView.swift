//
//  ChatInputView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/13/25.
//

import SwiftUI

struct ChatInputView: View {
    
    @Binding var isThinking: Bool
    @Binding var prompt: String
    
    let sendMessage: () async throws -> Void
    
    var body: some View {
        HStack {
            //Input text field
            VStack {
                TextEditor(text: $prompt)
                    .font(.title2)
                    .frame(height: 34)
                    .clipShape(.rect(cornerRadius: 8))
//                    .focused($promptFocusState) //for future Feature
                    .onKeyPress { keypress in
                        if keypress.key == .return {
                            Task {
                                try await self.sendMessage()
                            }
                            return .handled
                        } else {
                            return .ignored
                        }
                    }
            }
            .frame(height: 60)
            
            //Send button
            Button {
                if self.isThinking {
                    print("One message at a time, please!")
                } else {
                    Task {
                        try await self.sendMessage()
                    }
                }
            } label: {
                if self.isThinking {
                    ThinkingView()
                } else {
                    Label("Send", systemImage: "paperplane.fill")
                        .font(.title2)
                        .padding(.horizontal, Units.normalGap)
                        .padding(.vertical, Units.normalGap / 3.5)
                        .frame(minWidth: 100)
                }
            }
            .tint(self.isThinking ? .gray : .accent)
            .buttonStyle(.borderedProminent)
        }
        .frame(height: 60)
        .padding()
    }
}

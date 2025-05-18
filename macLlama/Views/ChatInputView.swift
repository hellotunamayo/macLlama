//
//  ChatInputView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/13/25.
//

import SwiftUI

struct ChatInputView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isThinking: Bool
    @Binding var prompt: String
    
    @State private var isTargeted: Bool = false
    @State private var image: NSImage?
    
    let sendMessage: () async throws -> Void
    
    var body: some View {
        HStack {
            //Input text field
            TextField("Ask me something...", text: $prompt)
                .font(.title2)
                .padding(.horizontal, 8)
                .textFieldStyle(.plain)
                .frame(height: 32)
                .background(
                    RoundedRectangle(cornerRadius: Units.normalGap / 3)
                        .stroke(colorScheme == .dark ? Color.gray.opacity(0.5) : Color.black.opacity(0.5), lineWidth: 1)
                )
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
        .onDrop(of: [.image], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            setImage(provider: provider)
            return true
        }
    }
    
    private func setImage(provider: NSItemProvider) {
        _ = provider.loadDataRepresentation(for: .image) { data, error in
            Task {
                guard error == nil, let data else {
                    print("Error loading data or no data available: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                await MainActor.run {
                    self.image = NSImage(data: data)
                    
                    // Optionally bind to `self.image` and print it if not nil.
                    guard let image = self.image else {
                        print("Failed to create image from the provided data.")
                        return
                    }
                    
                    print(image)
                }
            }
        }
    }
}

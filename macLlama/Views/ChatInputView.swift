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
    @Binding var images: [NSImage]
    
    @State private var isTargeted: Bool = false
    
    let sendMessage: () async throws -> Void
    
    var body: some View {
        VStack {
            ZStack {
                if images.isEmpty {
                    Label("Drop Images Here", systemImage: "photo.badge.plus")
                }
                
                RoundedRectangle(cornerRadius: Units.normalGap / 3)
                    .fill(.black.opacity(colorScheme == .dark ? 0.5 : 0.3))
                    .onDrop(of: [.image], isTargeted: $isTargeted) { providers in
                        guard let provider = providers.first else { return false }
                        setImage(provider: provider)
                        return true
                    }
            }
            .opacity(isTargeted ? 1 : 0.3)
            .frame(height: 70)
            .padding(.horizontal)
            .overlay {
                if !self.images.isEmpty {
                    ScrollView (.horizontal) {
                        HStack {
                            ForEach(0..<self.images.count, id: \.self) { index in
                                ZStack {
                                    GeometryReader { proxy in
                                        Image(nsImage: images[index])
                                            .resizable()
                                            .frame(width: Units.normalGap * 3,
                                                   height: Units.normalGap * 3)
                                            .padding(.horizontal, Units.normalGap / 8)
                                            .position(x: Units.normalGap * 2,
                                                      y: proxy.frame(in: .local).midY)
                                        
                                        Button {
                                            self.images.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark")
                                        }
                                        .background(Color.black)
                                        .buttonBorderShape(.circle)
                                        .clipShape(.circle)
                                        .position(x: 55, y: 13)
                                    }
                                    .frame(width: 70, height: 70)
                                }
                            }
                        }
                    }
                    .frame(height: 80)
                    .padding(.horizontal)
                }
            }
            
            //MARK: Text input
            HStack {
                //Input text field
                TextEditor(text: $prompt)
                    .font(.title2)
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                    .textFieldStyle(.plain)
                    .frame(height: 30)
                    .scrollContentBackground(.hidden)
                    .background(
                        RoundedRectangle(cornerRadius: Units.normalGap / 3)
                            .fill(Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1))
                    )
                    .onDrop(of: [.image], isTargeted: $isTargeted) { providers in
                        guard let provider = providers.first else { return false }
                        setImage(provider: provider)
                        return true
                    }
                
                //MARK: Send button
                Button {
                    if self.isThinking {
                        print("One message at a time, please!")
                    } else {
                        if !prompt.isEmpty {
                            Task {
                                try await self.sendMessage()
                            }
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
                .keyboardShortcut(.return) //WHY cmd+return???? ¯\(°_o)/¯
            }
            .frame(height: 60)
            .padding()
            .padding(.top, Units.normalGap * -1.5)
        }
    }
}

//MARK: Functions
extension ChatInputView {
    private func setImage(provider: NSItemProvider) {
        _ = provider.loadDataRepresentation(for: .image) { data, error in
            Task {
                guard error == nil, let data else {
                    debugPrint("Error loading data or no data available: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                await MainActor.run {
                    if let image = NSImage(data: data) {
                        self.images.append(image)
                    } else {
                        debugPrint("Error creating NSImage from data: Unknown error")
                    }
                }
            }
        }
    }
}

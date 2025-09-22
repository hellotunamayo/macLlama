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
    @Binding var isWebSearchEnabled: Bool
    @Binding var prompt: String
    @Binding var images: [NSImage]
    
    @State private var isTargeted: Bool = false
    @State private var isPopOverOn: Bool = false
    @FocusState private var isPromptFocused: Bool
    
    let sendMessage: () async throws -> Void
    let uploadedImageGridRows: [GridItem] = [GridItem(.fixed(30))]
    
    var body: some View {
        VStack {
            ZStack {
                if images.isEmpty {
                    Label("Drop Images Here", systemImage: "photo.badge.plus")
                        .greedyFrame(axis: .horizontal, alignment: .leading)
                        .padding(.leading, Units.normalGap * 0.85)
                }
                
                RoundedRectangle(cornerRadius: Units.normalGap / 3)
                    .fill(.black.opacity(colorScheme == .dark ? 0.5 : 0.2))
                    .onDrop(of: [.image], isTargeted: $isTargeted) { providers in
                        guard let provider = providers.first else { return false }
                        setImage(provider: provider)
                        return true
                    }
            }
            .opacity(isTargeted ? 1 : 0.3)
            .frame(height: 70)
            .padding(.horizontal)
            .padding(.bottom, Units.normalGap / 2.5)
            .overlay {
                imagePreview(images: self.images)
            }
            
            HStack {
                Button {
                    withAnimation(.default.speed(2.0)) {
                        isWebSearchEnabled.toggle()
                    }
                } label: {
                    Label("Web search mode: \(isWebSearchEnabled ? "On" : "Off")", systemImage: isWebSearchEnabled ? "safari.fill" : "safari")
                        .foregroundStyle(isWebSearchEnabled ? .green.opacity(0.7) : .secondary)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                
                Button {
                    isPopOverOn.toggle()
                } label: {
                    Label("Show details", systemImage: "info.circle")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isPopOverOn) {
                    Text("This feature is experimental.\nYou need to insert an Google Custom Search API key in the preferences.")
                        .padding()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Units.normalGap / 4)
            .padding(.leading)
            
            //MARK: Text input
            HStack(alignment: .bottom) {
                //Input text field
                ZStack {
                    if !isPromptFocused || self.prompt.isEmpty {
                        Text("Ask something (⌘ + return to send)")
                            .font(.title3)
                            .foregroundStyle(.secondary.opacity(0.6))
                            .frame(maxWidth: .infinity, maxHeight: 40, alignment: .leading)
                            .padding(.leading, Units.normalGap / 1.4)
                    }
                    
                    TextEditor(text: $prompt)
                        .focused($isPromptFocused)
                        .font(.title2)
                        .lineSpacing(Units.normalGap / 3)
                        .frame(minHeight: 32, maxHeight: Units.appFrameMinHeight / 4)
                        .dynamicTypeSize(.medium ... .xxLarge)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Units.normalGap * 0.6)
                        .padding(.leading, Units.normalGap / 2)
                }
                .scrollContentBackground(.hidden)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(Units.normalGap / 3)
                .padding(.top, Units.normalGap / 2)
                
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
                        Image(systemName: "rays")
                            .font(.title2)
                            .padding(.horizontal, Units.normalGap)
                            .padding(.vertical, Units.normalGap / 3.5)
                            .symbolEffect(.variableColor.iterative)
                            .frame(width: 36, height: 36)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                            .padding(.horizontal, Units.normalGap)
                            .padding(.vertical, Units.normalGap / 3.5)
                            .frame(width: 36, height: 36)
                    }
                }
                .tint(self.isThinking ? .gray : .accent)
                .buttonStyle(.borderedProminent)
                .clipShape(Circle())
                .keyboardShortcut(.return) //WHY cmd+return???? ¯\(°_o)/¯
            }
            .padding()
            .padding(.top, Units.normalGap * -1.5)
        }
    }
}

//MARK: Functions
extension ChatInputView {
    @ViewBuilder
    private func imagePreview(images: [NSImage]) -> some View {
        if images.count > 0 {
            ScrollView (.horizontal) {
                LazyHGrid(rows: uploadedImageGridRows) {
                    ForEach(0..<self.images.count, id: \.self) { index in
                        ZStack {
                            Image(nsImage: images[index])
                                .resizable()
                                .frame(width: Units.normalGap * 3,
                                       height: Units.normalGap * 3)
                                .padding(.horizontal, Units.normalGap / 8)
                            
                            Button {
                                self.images.remove(at: index)
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .background(Color.black)
                            .buttonBorderShape(.circle)
                            .clipShape(.circle)
                            .position(x: 48, y: 3)
                        }
                    }
                }
            }
            .frame(height: 80)
            .padding(.horizontal)
        }
    }
    
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

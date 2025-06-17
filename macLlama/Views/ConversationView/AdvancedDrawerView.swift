//
//  AdvancedDrawerView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 6/14/25.
//

import SwiftUI

struct AdvancedDrawerView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var showThink: Bool
    @Binding var localPrefix: String
    @Binding var localSuffix: String
    
    public var body: some View {
        VStack(alignment: .leading) {
            Section("Thinking Process") {
                Toggle("Enable thinking process", isOn: $showThink)
                    .greedyFrame(axis: .horizontal, alignment: .leading)
                
                Text("This functionality is intended for use with \"thinking\" models, including examples like DeepSeek R1 and Qwen 3. Attempting to use unsupported models will result in an error.\n(Requires Ollama 0.9.0 or later)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .greedyFrame(axis: .horizontal, alignment: .leading)
                    .frame(maxWidth: Units.appFrameMinWidth * 0.8)
                    .padding(.top, 2)
            }
            
            Divider()
                .padding(.vertical, Units.normalGap / 2)
            
            Section("Local Prefix & Suffix") {
                HStack {
                    TextField("Local Prompt Prefix", text: $localPrefix)
                    TextField("Local Prompt Suffix", text: $localSuffix)
                    Button {
                        self.localPrefix = ""
                        self.localSuffix = ""
                    } label: {
                        Label("Clear all", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: Units.chatBubbleMinWidth * 1.5)
            }
            .textFieldStyle(.roundedBorder)
        }
        .padding(.horizontal, Units.normalGap / 2)
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: Units.normalGap / 2)
                .fill(colorScheme == .dark ? .black : .white)
        )
    }
}

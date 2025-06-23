//
//  ChatSidebarView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 6/23/25.
//

import SwiftUI

struct ChatSidebarView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var showThink: Bool
    @Binding var localPrefix: String
    @Binding var localSuffix: String
    @Binding var predict: Double
    @Binding var temperature: Double
    
    var decimalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }
    
    public var body: some View {
        ScrollView {
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
                    VStack {
                        TextField("Local Prompt Prefix", text: $localPrefix)
                        TextField("Local Prompt Suffix", text: $localSuffix)
                    }
                    .frame(maxWidth: Units.chatBubbleMinWidth * 1.5)
                    
                    Button {
                        self.localPrefix = ""
                        self.localSuffix = ""
                    } label: {
                        Label("Clear all", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
                .textFieldStyle(.roundedBorder)
                
                Divider()
                    .padding(.vertical, Units.normalGap / 2)
                
                Section("Advanced Settings") {
                    Text("Adjusting 'temperature' and 'num_predict' can significantly impact the model's output. Higher temperatures lead to more creative, but potentially less predictable, responses. A larger 'num_predict' may result in longer, more verbose outputs, and can also increase processing time.  Experiment with caution.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                        .greedyFrame(axis: .horizontal, alignment: .leading)
                        .frame(maxWidth: Units.appFrameMinWidth * 0.8)
                        .padding(.top, 2)
                    
                    VStack {
                        TextField("num_predict (-1 for unlimited)", value: $predict, formatter: decimalFormatter)
                        TextField("temperature", value: $temperature, formatter: decimalFormatter)
                    }
                    .frame(maxWidth: Units.chatBubbleMinWidth * 1.5)
                }
            }
            .padding(.horizontal, Units.normalGap / 2)
            .padding(.vertical)
        }
    }
}

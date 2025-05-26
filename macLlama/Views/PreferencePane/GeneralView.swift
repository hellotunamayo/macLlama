//
//  GeneralView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/22/25.
//

import SwiftUI

struct GeneralView: View {
    @Binding var serverKillWithApp: Bool
    @Binding var isAutoScrollEnabled: Bool
    @Binding var promptSuffix: String
    @Binding var isAutoUpdateEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Section("General") {
                List {
                    Toggle(isOn: $serverKillWithApp) {
                        Text("Automatically stop Ollama server on exit")
                            .padding(.leading, 3)
                    }
                    .padding(.vertical, 5)
                    
                    Toggle(isOn: $isAutoScrollEnabled) {
                        Text("Auto-scroll to bottom on answer completion")
                            .padding(.leading, 3)
                    }
                    .padding(.vertical, 5)
                    
                    Toggle(isOn: $isAutoUpdateEnabled) {
                        Text("Automatic check for Updates")
                            .padding(.leading, 3)
                    }
                    .padding(.vertical, 5)
                }
                .clipShape(.rect(cornerRadius: Units.normalGap / 2))
            }
            
            Section("Prompt") {
                List {
                    HStack {
                        Text("Prompt Suffix:")
                        TextField("Prompt suffix", text: $promptSuffix)
                            .textFieldStyle(.roundedBorder)
                            .padding(.leading, 3)
                    }
                    .padding(.vertical, 5)
                }
                .clipShape(.rect(cornerRadius: Units.normalGap / 2))
            }
            Spacer()
        }
        .padding()
    }
}

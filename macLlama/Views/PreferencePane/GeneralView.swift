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
    
    var body: some View {
        VStack(alignment: .leading) {
            Section("General") {
                List {
                    Toggle(isOn: $serverKillWithApp) {
                        Text("Stop Ollama Server Automatically on App Exit")
                            .padding(.leading, 3)
                    }
                    .padding(.vertical, 5)
                    
                    Toggle(isOn: $isAutoScrollEnabled) {
                        Text("Auto scroll while generating answer")
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

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
    @Binding var hostAddress: String
    @Binding var hostPort: Int
    @Binding var hostProtocol: String
    
    let httpProtocol: [String] = ["http://", "https://"]
    
    var body: some View {
        VStack(alignment: .leading) {
            Section("General") {
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
            
            Divider().padding(.vertical)
            
            Section("Network") {
                HStack {
                    Picker(selection: $hostProtocol) {
                        ForEach(httpProtocol, id: \.self) { item in
                            Text(item)
                        }
                    } label: {
                        Text("Host info: ")
                    }
                    
                    TextField("Host", text: $hostAddress)
                        .textFieldStyle(.roundedBorder)
                    Text(":")
                    TextField("Port", value: $hostPort, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 80)
                }
                
                Text("This option is for experienced users. If you're unsure, leave it at the standard setting.\nBy default, the host is localhost and the port is 11434.")
                    .font(.caption)
                    .lineSpacing(4)
                    .padding(.top, Units.normalGap / 2)
                    .foregroundStyle(.secondary)
            }
            
            Divider().padding(.vertical)
            
            Section("Prompt") {
                HStack {
                    Text("Prompt Suffix:")
                    TextField("Prompt suffix", text: $promptSuffix)
                        .textFieldStyle(.roundedBorder)
                        .padding(.leading, 3)
                }
                .padding(.vertical, 5)
            }
            Spacer()
        }
        .padding()
    }
}

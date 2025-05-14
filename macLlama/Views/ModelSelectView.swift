//
//  ModelSelectView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/13/25.
//

import SwiftUI

struct ModelSelectView: View {
    @EnvironmentObject var serverStatus: ServerStatusIndicator
    @Binding var modelList: [OllamaModel]
    @Binding var currentModel: String
    @Binding var ollamaNetworkService: OllamaNetworkService?
    @Binding var isModelLoading: Bool
    
    let reloadButtonAction: () -> Void
    
    var body: some View {
        HStack{
            Circle()
                .fill(serverStatus.indicator ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Picker("Current Model", selection: $currentModel) {
                ForEach(modelList, id: \.self) { model in
                    Text(model.name)
                        .foregroundStyle(.primary)
                        .tag(model.name)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: Units.appFrameMinWidth * 0.5)
            .onChange(of: currentModel) { oldValue, newValue in
                Task {
                    await self.ollamaNetworkService?.changeModel(model: newValue)
                }
            }
            
            Button {
                withAnimation {
                    self.isModelLoading.toggle()
                }
                
                Task {
                    self.isModelLoading = true
                    
                    if try await OllamaNetworkService.isServerOnline() {
                        reloadButtonAction()
                        serverStatus.updateServerStatusIndicatorTo(true)
                    } else {
                        serverStatus.updateServerStatusIndicatorTo(false)
                        modelList.removeAll()
                    }
                    
                    self.isModelLoading = false
                }
                
            } label: {
                VStack {
                    if self.isModelLoading {
                        Label("Loading...", systemImage: "rays")
                    } else {
                        Label("Reload", systemImage: "arrow.clockwise")
                    }
                }
                .padding(.vertical, Units.normalGap / 8)
                .frame(width: 80)
            }
            .tint(.primary)
            .controlSize(.regular)
            .buttonStyle(.bordered)
        }
        .padding()
        .task {
            guard let isServerOnline = try? await OllamaNetworkService.isServerOnline() else { return }
            serverStatus.updateServerStatusIndicatorTo(isServerOnline)
        }
    }
}

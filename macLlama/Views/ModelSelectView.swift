//
//  ModelSelectView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/13/25.
//

import SwiftUI

struct ModelSelectView: View {
    @EnvironmentObject var serverStatus: ServerStatus
    @Binding var modelList: [OllamaModel]
    @Binding var currentModel: String
    @Binding var isModelLoading: Bool
    
    let ollamaNetworkService: OllamaNetworkService
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
                    if !currentModel.isEmpty {
                        await self.ollamaNetworkService.changeModel(model: newValue)
                    }
                }
            }
            
            Button {
                withAnimation {
                    self.isModelLoading.toggle()
                }
                
                Task {
                    self.isModelLoading = true
                    
                    try? await serverStatus.updateServerStatus()
                    
                    if serverStatus.indicator {
                        reloadButtonAction()
                    } else {
                        modelList.removeAll()
                    }
                    
                    try? await serverStatus.updateServerStatus()
                    self.isModelLoading = false
                }
                
            } label: {
                VStack {
                    if self.isModelLoading {
                        Label("Loading...", systemImage: "rays")
                            .padding(.horizontal, 4)
                    } else {
                        Label("Reload", systemImage: "arrow.clockwise")
                            .padding(.horizontal, 4)
                    }
                }
                
//                .padding(.vertical, Units.normalGap / 8)
//                .frame(width: 80)
                .labelStyle(.titleAndIcon)
            }
            .tint(.primary)
//            .controlSize(.regular)
//            .buttonStyle(.)
        }
        .padding()
        .task {
            try? await serverStatus.updateServerStatus()
        }
    }
}

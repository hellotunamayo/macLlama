//
//  ModelSelectView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/13/25.
//

import SwiftUI

struct ModelSelectView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openWindow) var openWindow
    @EnvironmentObject var serverStatus: ServerStatus
    @Binding var modelList: [OllamaModel]
    @Binding var currentModel: String
    @Binding var isModelLoading: Bool
    @Binding var isSettingOn: Bool
    
    @State private var isModelSelecting: Bool = false
    @State private var glassContainerGap: CGFloat = Units.normalGap * 2.2
    
    let ollamaNetworkService: OllamaNetworkService
    let reloadButtonAction: () -> Void
    let modelSelectPositionX: CGFloat = Units.appFrameMinWidth * 0.4 * 0.55
    let modelSelectWidth: CGFloat = Units.appFrameMinWidth * 0.5
    
    static var modelNameWithRemovedPrefix: (String) -> String? {
        { modelName in
            let pattern = "hf\\.co/[^/]+/"
            do{
                let regex = try NSRegularExpression(pattern: pattern)
                let range = NSRange(location: 0, length: modelName.utf8.count)
                return regex.stringByReplacingMatches(in: modelName, options: [], range: range, withTemplate: "")
            } catch {
                return nil
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                if #available(macOS 26.0, *) {
                    Circle()
                        .fill(serverStatus.isOnline ? Color.green.opacity(0.8) : Color.red.opacity(0.8))
                        .glassEffect()
                        .frame(width: 8, height: 8)
                } else {
                    Circle()
                        .fill(serverStatus.isOnline ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                }
                
                CutomModelSelectPickerView(currentModel: $currentModel, modelList: $modelList)
                
                Button {
                    withAnimation {
                        self.isModelLoading.toggle()
                    }
                    
                    Task {
                        self.isModelLoading = true
                        
                        try? await serverStatus.updateServerStatus()
                        
                        if serverStatus.isOnline {
                            reloadButtonAction()
                        } else {
                            modelList.removeAll()
                            self.isModelLoading = false
                        }
                        
                        try? await serverStatus.updateServerStatus()
                        self.isModelLoading = false
                    }
                    
                } label: {
                    ZStack {
                        if #available(macOS 26.0, *){
                            Circle()
                                .fill(.white.opacity(0.0001))
                                .glassEffect()
                        } else {
                            Circle()
                                .fill(colorScheme == .dark ? .gray.opacity(0.5) : .gray.opacity(0.2))
                        }
                        
                        if self.isModelLoading {
                            Image(systemName: "rays")
                                .symbolEffect(.variableColor.iterative)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .padding(.vertical, Units.normalGap / 8)
                    .frame(width: 32, height: 32)
                }
                .controlSize(.regular)
                .buttonStyle(.plain)
                
                Spacer()
                
                if #available(macOS 26.0, *) {
                    GlassEffectContainer(spacing: Units.normalGap * 2.5) {
                        HStack(spacing: Units.normalGap * 2.5) {
                            Button {
                                isSettingOn.toggle()
                            } label: {
                                Image(systemName: "gear")
                            }
                            .buttonStyle(.plain)
                            .frame(width: Units.normalGap * 2.5, height: Units.normalGap * 2.5)
                            .glassEffect()
                            .offset(x: glassContainerGap)
                            
                            Button {
                                openWindow(id: "chatHistory")
                            } label: {
                                Image(systemName: "list.bullet")
                            }
                            .buttonStyle(.plain)
                            .frame(width: Units.normalGap * 2.5, height: Units.normalGap * 2.5)
                            .glassEffect()
                        }
                    }
                } else {
                    HStack {
                        Button {
                            isSettingOn.toggle()
                        } label: {
                            Image(systemName: "gear")
                        }
                        .buttonStyle(.bordered)
                        .frame(width: Units.normalGap * 2.5, height: Units.normalGap * 2.5)
                        
                        Button {
                            openWindow(id: "chatHistory")
                        } label: {
                            Image(systemName: "list.bullet")
                        }
                        .buttonStyle(.bordered)
                        .frame(width: Units.normalGap * 2.5, height: Units.normalGap * 2.5)
                    }
                }
            }
            .greedyFrame(axis: .horizontal, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding()
            .task {
                try? await serverStatus.updateServerStatus()
            }
        }
    }
}

//
//  ModelSelectView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/13/25.
//

import SwiftUI

struct ModelSelectView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var serverStatus: ServerStatus
    @Binding var modelList: [OllamaModel]
    @Binding var currentModel: String
    @Binding var isModelLoading: Bool
    
    @State private var isModelSelecting: Bool = false
    
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
            HStack{
                Circle()
                    .fill(serverStatus.isOnline ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                GeometryReader { geometry in
                    VStack {
                        Button(action: {
                            withAnimation(.default.speed(2.0)) {
                                self.isModelSelecting.toggle()
                            }
                        }, label: {
                            ZStack {
                                Capsule()
                                    .fill(colorScheme == .dark ? .black.opacity(0.4) : .gray.opacity(0.1))
                                
                                Text(ModelSelectView.modelNameWithRemovedPrefix(currentModel) ?? "Unknown Model")
                                    .lineLimit(1)
                                    .greedyFrame(axis: .horizontal, alignment: .leading)
                                    .padding(.horizontal)
                            }
                        })
                        .buttonStyle(.plain)
                        .position(x: self.modelSelectPositionX,
                                  y: geometry.bounds(of: .named("CustomSelection"))!.minY + Units.normalGap)
                        .frame(width: self.modelSelectWidth, height: Units.normalGap * 2)
                        .zIndex(2)
                        
                        if isModelSelecting {
                            self.modelSelectionScrollView(geometry: geometry)
                        }
                    }
                    .padding(.horizontal)
                    .task {
                        guard let lastModelUsed = UserDefaults.standard.string(forKey: "currentModel") else { return }
                        if lastModelUsed.count > 0, currentModel.count > 0 {
                            await self.ollamaNetworkService.changeModel(model: lastModelUsed)
                            self.currentModel = lastModelUsed
                        }
                    }
                }
                .coordinateSpace(.named("CustomSelection"))
                .frame(maxWidth: Units.appFrameMinWidth * 0.5)
                
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
                        Circle()
                            .fill(colorScheme == .dark ? .gray.opacity(0.5) : .gray.opacity(0.2))
                        
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

//MARK: ViewBuilders
extension ModelSelectView {
    @ViewBuilder
    private func modelSelectionScrollView(geometry: GeometryProxy) -> some View {
        if #available(macOS 26.0, *) {
            ScrollView {
                VStack {
                    ForEach(modelList, id: \.self) { model in
                        HStack {
                            Text(ModelSelectView.modelNameWithRemovedPrefix(model.name) ?? "Unknown Model")
                                .lineLimit(1)
                                .foregroundStyle(.primary)
                                .padding(.horizontal)
                                .padding(.vertical, Units.normalGap * 0.30)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.0001))
                        .onTapGesture {
                            self.currentModel = model.name
                            withAnimation(.default.speed(2.0)) {
                                self.isModelSelecting = false
                            }
                        }
                    }
                }
                .padding(Units.normalGap)
            }
            .position(x: self.modelSelectPositionX,
                      y: geometry.frame(in: .global).minY * 1.5)
            .frame(width: self.modelSelectWidth, height: Units.appFrameMinHeight * 0.25)
            .glassEffect(in: .rect(cornerRadius: 8.0).offset(x: 0, y: Units.normalGap / 8.0))
            .offset(x: Units.normalGap * -0.9)
            .zIndex(1)
        } else {
            ScrollView {
                VStack {
                    ForEach(modelList, id: \.self) { model in
                        HStack {
                            Text(ModelSelectView.modelNameWithRemovedPrefix(model.name) ?? "Unknown Model")
                                .lineLimit(1)
                                .foregroundStyle(.primary)
                                .padding(.horizontal)
                                .padding(.vertical, Units.normalGap * 0.33)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.0001))
                        .onTapGesture {
                            self.currentModel = model.name
                            withAnimation(.default.speed(2.0)) {
                                self.isModelSelecting = false
                            }
                        }
                    }
                }
                .padding(Units.normalGap)
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ? .black : Color(red: 244/255, green: 244/255, blue: 244/255))
                    .stroke(colorScheme == .dark ? .black : .gray.opacity(0.15), lineWidth: 1.0)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 0)
            )
            .position(x: self.modelSelectPositionX,
                      y: geometry.frame(in: .global).minY * 1.5)
            .frame(width: self.modelSelectWidth, height: Units.appFrameMinHeight * 0.25)
            .offset(x: Units.normalGap * -0.9)
            .zIndex(1)
        }
    }
}

//
//  SecondSuggestionView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 7/19/25.
//

import SwiftUI

enum ModelMemoryUsage: String {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
}

struct SecondSuggestionView: View {
    @Binding var selectedPurpose: [SuggestionModelPurpose]
    @Binding var isShowing: Bool
    @Binding var step: Int
    
    @State private var suggestedModel: [SuggestionModel] = []
    @State private var cpuInfo: String?
    @State private var psysicalMemory: UInt64?
    @State private var processorCount: UInt64?
    @State private var isPopoverShowing: Bool = false
    @State private var installedModels: [OllamaModel] = []
    
    let viewModel: ModelSuggestionViewModel
    let modelManagementViewModel: ModelManagementViewModel
    let systemInfoService: SystemInfoService = .init()
    
    var memoryUsage: (UInt64) -> ModelMemoryUsage {
        { usage in
            switch usage {
                case ..<(1024 * 1024 * 1024 * 7):
                    return .small
                case (1024 * 1024 * 1024 * 7)...(1024 * 1024 * 1024 * 22):
                    return .medium
                default:
                    return .large
            }
        }
    }
    
    var body: some View {
        VStack {
            if suggestedModel.isEmpty {
                Image("ollama_warning")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 90, height: 90)
                    .offset(y: -16)
                
                Text("Sorry, no suitable model found.")
                    .font(.title2)
            } else {
                List(suggestedModel) { model in
                    HStack {
                        Text("\(model.fullName)")
                            .font(.title3)
                            .lineLimit(1)
                            .padding(.vertical, 4)
                            
                        MemoryUsageIndicatorView(memoryUsage: memoryUsage(model.modelParameterCount))
                            .padding(.leading, 8)
                        
                        Spacer()
                        
                        if self.installedModels.contains(where: { $0.name == model.fullName }) {
                            Label("Already Installed", systemImage: "checkmark.circle")
                                .foregroundStyle(.green)
                        } else {
                            if let urlString = model.urlString {
                                Link(destination: URL(string: urlString)!) {
                                    Image(systemName: "safari")
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            Button {
                                self.isShowing = false
                                Task {
                                    try await self.modelManagementViewModel.pullModel(model.fullName)
                                }
                            } label: {
                                Label("Install", systemImage: "square.and.arrow.down")
                                    .foregroundStyle(.primary)
                            }
                            .tint(.primary)
                            .buttonStyle(.bordered)
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listSectionSeparator(.hidden)
                    
                    Divider()
                }
                .padding(.bottom)
                
                HStack {
                    Spacer()
                    
                    Button {
                        self.isPopoverShowing.toggle()
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .aspectRatio(contentMode: .fit)
                    }
                    .popover(isPresented: self.$isPopoverShowing, arrowEdge: .bottom) {
                        VStack(alignment: .leading) {
                            Text("Small Models (2-8GB of memory usage): Ideal for simpler tasks and can run on standard hardware.")
                            Divider()
                            Text("Medium Models (8-32GB of memory usage): Offer a good balance for general tasks.")
                            Divider()
                            Text("Large Models (32GB or more of memory usage): Very powerful, but require significant resources and have higher costs. Best for complex projects.")
                        }
                        .padding()
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                
                HStack {
                    Button {
                        withAnimation {
                            self.step -= 1
                        }
                    } label: {
                        Label("Previous", systemImage: "arrow.left")
                            .padding(.horizontal)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.extraLarge)
                    
                    Button {
                        self.isShowing = false
                    } label: {
                        Label("Close", systemImage: "xmark")
                            .padding(.horizontal)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.extraLarge)
                }
            }
        }
        .task {
            #if DEBUG
            debugPrint(self.selectedPurpose)
            #endif
            //get system information
            self.cpuInfo = await self.systemInfoService.getCPUInfo() ?? "Unknown"
            self.psysicalMemory = await self.systemInfoService.getProcessInfo(.psysicalMemory)
            self.processorCount = await self.systemInfoService.getProcessInfo(.processorCount)
            await self.suggestion()
            
            //set current installed models
            guard let installedModels = try? await OllamaNetworkService.getModels() else {
                return
            }
            self.installedModels = installedModels
        }
    }
    
    func suggestion() async {
        let suggestionByPurpose = await self.viewModel.modelSuggestionBy(purpose: self.selectedPurpose)
        let suggestionByMemory = await self.viewModel.modelSuggestionBy(memory: self.psysicalMemory ?? 0, from: suggestionByPurpose)
        self.suggestedModel = suggestionByMemory
    }
}

//#Preview {
//    SecondSuggestionView(selectedPurpose: .constant([.codeGeneration]),
//                         isShowing: .constant(true), step: .constant(2),
//                         viewModel: .init(),
//                         modelManagementViewModel: .init())
//}

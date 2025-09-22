//
//  ModelManagementView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/22/25.
//

import SwiftUI

struct ModelManagementView: View {
    @State private var modelList: [String] = []
    @State private var isAlertPresented: Bool = false
    @State private var selectedModel: String = ""
    @State private var modelNameToPull: String = ""
    @State private var pullingProgressPipeText: String = ""
    @State private var isModelPulling: Bool = false
    @State private var isSheetPresented: Bool = false
    
    @StateObject private var viewModel: ModelManagementViewModel = .init()
    
    var body: some View {
        VStack(alignment: .leading) {
            Section("Model Management") {
                List(modelList, id: \.self, selection: $selectedModel) { modelName in
                    HStack {
                        Text(modelName)
                            .greedyFrame(axis: .horizontal, alignment: .leading)
                            .padding(.vertical, Units.normalGap * 0.3)
                    }
                }
                .tableColumnHeaders(.visible)
                .listStyle(.plain)
                .frame(height: Units.appFrameMinHeight / 4)
                .clipShape(.rect(cornerRadius: Units.normalGap / 2))
                .task {
                    await refreshModelList()
                }
                
                HStack(alignment: .top) {
                    Text("\(modelList.count) models available")
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                        .frame(alignment: .leading)
                        
                    Spacer()
                    
                    Button {
                        Task {
                            await refreshModelList()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .tint(Color.gray)
                    .buttonStyle(.plain)
                    .frame(idealWidth: Units.controlDefaultSize,
                           idealHeight: Units.controlDefaultSize,
                           alignment: .trailing)
                    
                    Button {
                        self.isAlertPresented.toggle()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .alert("Delete model\n\"\(selectedModel)\"?", isPresented: $isAlertPresented) {
                        Button("Delete", role: .destructive) {
                            Task {
                                guard let (pipe, process) = try await ShellService.runShellScript("ollama rm \(selectedModel)") else { return }
                                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                                let output = String(data: data, encoding: .utf8) ?? "No output"
                                debugPrint(output)
                                process.waitUntilExit()
                                
                                await refreshModelList()
                            }
                        }
                    } message: {
                        Text("This action cannot be undone.")
                    }
                    .frame(idealWidth: 22, idealHeight: 22, alignment: .trailing)
                }
                .padding(.horizontal, Units.normalGap / 2)
                .padding(.top, 3)
            }

            Divider().padding(.vertical)
            
            Section() {
                HStack {
                    Text("Add model to macLlama")
                    Spacer()
                    self.suggestionModelView(models: self.modelList.isEmpty)
                }
                .sheet(isPresented: self.$isSheetPresented) {
                    ModelSuggestionView(isSheetPresent: self.$isSheetPresented, modelManagementViewModel: self.viewModel)
                }
                
                HStack {
                    TextField("Model name to pull", text: $modelNameToPull)
                        .textFieldStyle(.roundedBorder)
                    
                    Button {
                        if !isModelPulling {
                            isModelPulling.toggle()
                            Task {
                                pullingProgressPipeText = self.viewModel.pullingProgressPipeText ?? ""
                                try await viewModel.pullModel(modelNameToPull)
                            }
                        } else {
                            debugPrint("Pull already in progress...")
                        }
                    } label: {
                        if isModelPulling {
                            Label("Pulling \(modelNameToPull)...", systemImage: "rays")
                                .symbolEffect(.variableColor.iterative)
                        } else {
                            Label("Pull", systemImage: "arrow.down")
                        }
                    }
                }
                
                TextEditor(text: $pullingProgressPipeText)
                    .disabled(true)
                    .onReceive(self.viewModel.$pullingProgressPipeText) { newValue in
                        self.pullingProgressPipeText = newValue ?? ""
                    }
                    .onChange(of: self.viewModel.pullingProgressPipeText) { _, newValue in
                        Task {
                            if newValue == "" {
                                await self.refreshModelList()
                                self.isModelPulling = false
                            }
                        }
                    }
            }
            
            Spacer()
        }
        .padding()
    }
}

//MARK: Functions
extension ModelManagementView {
    
    @ViewBuilder
    func suggestionModelView(models isModelEmpty: Bool) -> some View {
        if isModelEmpty {
            Button {
                self.isSheetPresented = true
            } label: {
                Label("Model Suggestion", systemImage: "wand.and.sparkles.inverse")
                    .symbolEffect(.pulse.wholeSymbol, options: .speed(2.0))
            }
            .buttonStyle(.borderedProminent)
        } else {
            Button {
                self.isSheetPresented = true
            } label: {
                Label("Model Suggestion", systemImage: "wand.and.sparkles.inverse")
            }
            .buttonStyle(.bordered)
        }
        
    }
    
    private func refreshModelList() async {
        self.modelList.removeAll()
        guard let models = try? await OllamaNetworkService.getModels() else {
            return
        }
        for model in models {
            self.modelList.append(model.name)
        }
    }
}

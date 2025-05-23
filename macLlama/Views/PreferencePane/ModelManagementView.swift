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
    
    var body: some View {
        VStack(alignment: .leading) {
            Section("Model Management") {
                List(modelList, id: \.self, selection: $selectedModel) { modelName in
                    HStack {
                        Text(modelName)
                            .greedyFrame(alignment: .leading)
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

            Divider()
                .padding(.vertical)
            
            Section("Add Model from Ollama.com") {
                HStack {
                    TextField("Model name to pull", text: $modelNameToPull)
                        .textFieldStyle(.roundedBorder)
                    
                    Button {
                        if !isModelPulling {
                            isModelPulling.toggle()
                            Task {
                                try await self.pullModel(modelNameToPull)
                            }
                        } else {
                            debugPrint("Pull already in progress...")
                        }
                    } label: {
                        if isModelPulling {
                            Label("Pulling \(modelNameToPull)...", systemImage: "rays")
                        } else {
                            Label("Pull", systemImage: "arrow.down")
                        }
                    }
                }
                
                TextEditor(text: $pullingProgressPipeText)
                    .disabled(true)
                    .onChange(of: pullingProgressPipeText) { _, newValue in
                        if newValue == "" {
                            Task {
                                await self.refreshModelList()
                                isModelPulling = false
                            }
                        }
                    }
            }
            
            Spacer()
        }
        .frame(height: 600)
        .padding()
    }
}

//MARK: Functions
extension ModelManagementView {
    private func refreshModelList() async {
        self.modelList.removeAll()
        guard let models = try? await OllamaNetworkService.getModels() else {
            return
        }
        for model in models {
            self.modelList.append(model.name)
        }
    }
    
    private func pullModel(_ modelName: String) async throws {
        let customPath = "PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        let process = Process()
        let url = URL(fileURLWithPath: "/bin/zsh")
        let pipe = Pipe()
        let outHandle = pipe.fileHandleForReading
        
        process.executableURL = url
        process.standardOutput = pipe
        process.standardError = pipe
        process.arguments = ["-c", "\(customPath) ollama pull \(modelName)"]
        
        outHandle.readabilityHandler = { pipeHandle in
            if let line = String(data: pipeHandle.availableData, encoding: .utf8) {
                Task { @MainActor in
                    pullingProgressPipeText = line
                }
            } else {
                print("Error decoding data: \(pipeHandle.availableData)")
            }
        }
        
        do {
            try process.run()
        } catch {
            debugPrint("🔴Failed to run shell script.")
        }
    }
}

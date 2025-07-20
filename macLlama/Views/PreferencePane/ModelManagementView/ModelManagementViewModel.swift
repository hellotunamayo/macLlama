//
//  ModelManagementViewModel.swift
//  macLlama
//
//  Created by Minyoung Yoo on 7/20/25.
//

import Foundation

// @unchecked declared temporarily.
// Will be refactored later.
final class ModelManagementViewModel: ObservableObject, @unchecked Sendable {
    
    @Published private(set) var pullingProgressPipeText: String?
    
    func pullModel(_ modelName: String) async throws {
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
                    self.pullingProgressPipeText = line
                }
            } else {
                print("Error decoding data: \(pipeHandle.availableData)")
            }
        }
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            debugPrint("🔴Failed to run shell script.")
        }
    }
}


//
//  Utility.swift
//  OllamaUIApp
//
//  Created by Minyoung Yoo on 5/11/25.
//

import Foundation

actor ShellService {
    
    
    ///Run shell script
    static func runShellScript(_ command: String) async -> String? {
        let customPath = "PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        let fullCommand = "\(customPath) \(command)"
        let process = Process()
        let url = URL(fileURLWithPath: "/bin/zsh")
        let pipe = Pipe()
        
        process.executableURL = url
        process.arguments = ["-c", fullCommand]
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            return "Ollama service is running"
        } catch {
            return nil
        }
    }
    
    ///kill ollama
    static func killOllama() {
        let customPath = "PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        let fullCommand = "\(customPath) killall ollama"
        let process = Process()
        let url = URL(fileURLWithPath: "/bin/zsh")
        let pipe = Pipe()
        
        process.executableURL = url
        process.arguments = ["-c", fullCommand]
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return
        }
        
        print("🟢ollama process is successfully killed.")
    }
}


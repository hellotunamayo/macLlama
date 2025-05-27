//
//  Utility.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/11/25.
//

import Foundation
import AppKit

enum ShellCommand: String {
    case startServer = "ollama serve > ~/macLlama-output.log 2>&1" //Temporary solution!
//    case startServer = "ollama serve 2>&1 | logger"
}

actor ShellService {
    
    ///Open Terminal.app
    static func openTerminal() async throws {
        guard let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal")
        else { return }
        
        try await NSWorkspace.shared.open([], withApplicationAt: appUrl,
                                          configuration: NSWorkspace.OpenConfiguration() )
    }
    
    ///Run shell script
    static func runShellScript(_ command: String) async throws -> (Pipe, Process)? {
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
            return (pipe, process)
        } catch {
#if DEBUG
            debugPrint("🔴Failed to run shell script.")
#endif
            return nil
        }
    }
    
    ///Kill ollama server
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
            debugPrint("🟢ollama process is successfully killed.")
        } catch {
            debugPrint("An error occured while killing ollama process: \(error)")
            return
        }
    }
}


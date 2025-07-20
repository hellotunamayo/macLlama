//
//  SystemInfoService.swift
//  macLlama
//
//  Created by Minyoung Yoo on 7/19/25.
//

import Foundation

actor SystemInfoService {
    enum ProcessType {
        case processorCount, psysicalMemory
    }
    
    func getCPUInfo() async -> String? {
        let task = Process()
        let pipe = Pipe()
        let shellCommand = "sysctl -n machdep.cpu.brand_string"
        
        task.standardOutput = pipe
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-c", shellCommand]
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)
            task.waitUntilExit()
            return output
        } catch {
#if DEBUG
            debugPrint("Error running shell command: \(error)")
            return nil
#else
            return nil
#endif
        }
    }
    
    func getProcessInfo(_ processType: ProcessType) async -> UInt64 {
        switch processType {
            case .processorCount:
                return UInt64(ProcessInfo.processInfo.processorCount)
            case .psysicalMemory:
                return ProcessInfo.processInfo.physicalMemory
        }
    }
}

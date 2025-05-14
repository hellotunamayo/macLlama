//
//  Extras.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/14/25.
//

import Foundation

final class ServerStatus: ObservableObject {
    private(set) var isRunning: Bool = false
    
    public func updateServerStatusTo(_ status: Bool) {
        isRunning = status
    }
}

//
//  Extras.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/14/25.
//

import Foundation

@MainActor
final class ServerStatusIndicator: ObservableObject {
    @Published private(set) var indicator: Bool = false
    
    func updateServerStatusIndicatorTo(_ status: Bool) {
        self.indicator = status
    }
}

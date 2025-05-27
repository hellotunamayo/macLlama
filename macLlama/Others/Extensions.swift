//
//  Extensions.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/23/25.
//

import SwiftUI

struct GreedyFrame: ViewModifier {
    var alignment: Alignment = .center
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity,
                   maxHeight: .infinity,
                   alignment: self.alignment)
    }
}

extension View {
    func greedyFrame(alignment: Alignment = .center) -> some View {
        modifier(GreedyFrame(alignment: alignment))
    }
}

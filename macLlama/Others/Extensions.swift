//
//  Extensions.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/23/25.
//

import SwiftUI

struct GreedyFrame: ViewModifier {
    var axis: Axis
    var alignment: Alignment
    
    func body(content: Content) -> some View {
        if axis != .horizontal {
            content
                .frame(maxHeight: .infinity, alignment: self.alignment)
        } else {
            content
                .frame(maxWidth: .infinity, alignment: self.alignment)
        }
    }
}

extension View {
    func greedyFrame(axis: Axis, alignment: Alignment = .center) -> some View {
        modifier(GreedyFrame(axis: axis, alignment: alignment))
    }
}

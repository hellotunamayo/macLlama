//
//  MemoryUsageView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 7/22/25.
//

import SwiftUI

struct MemoryUsageIndicatorView: View {
    let memoryUsage: ModelMemoryUsage
    
    var body: some View {
        ZStack {
            switch memoryUsage {
                case .small:
                    Capsule()
                        .stroke(style: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(.mint)
                        .background(Color.mint.opacity(0.1))
                    Text(memoryUsage.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.mint)
                case .medium:
                    Capsule()
                        .stroke(style: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(.orange)
                        .background(Color.orange.opacity(0.1))
                    Text(memoryUsage.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                case .large:
                    Capsule()
                        .stroke(style: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(.red)
                        .background(Color.red.opacity(0.1))
                    Text(memoryUsage.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
            }
        }
        .clipShape(Capsule())
        .frame(maxWidth: CGFloat(memoryUsage.rawValue.count) * 11, maxHeight: Units.controlMinimumSize)
    }
}

//#Preview {
//    MemoryUsageView(memoryUsage: .medium)
//}

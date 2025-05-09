//
//  ThinkingView.swift
//  OllamaUIApp
//
//  Created by Minyoung Yoo on 5/8/25.
//

import SwiftUI

struct ThinkingView: View {
    var body: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.6)
            Text("Thinking...")
                .font(.title2)
                .padding(.trailing, 10)
        }
        .frame(minWidth: 100)
    }
}

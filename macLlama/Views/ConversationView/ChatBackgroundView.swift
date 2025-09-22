//
//  ChatBackgroundView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/12/25.
//

import SwiftUI

struct ChatBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Image("macLlama-gray")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: Units.appFrameMinHeight / 3, maxHeight: Units.appFrameMinHeight / 3)
                .offset(y: Units.appFrameMinHeight / 20 * -1)
                .opacity(self.colorScheme == .dark ? 0.03 : 0.04)
        }
    }
}

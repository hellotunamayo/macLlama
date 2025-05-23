//
//  TypographyView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/22/25.
//

import SwiftUI

struct TypographyView: View {
    @Binding var chatFontSize: Int
    
    private var chatFontSizeProxy: Binding<Double> {
        Binding<Double>(
            get: {
                Double(chatFontSize)
            },
            set: {
                chatFontSize = Int($0)
            }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Section("Chat font size") {
                List{
                    HStack {
                        //TODO: Add slider graphical indicator
                        Slider(value: chatFontSizeProxy, in: 12...32)
                        Text("\(chatFontSize)pt")
                        Button {
                            chatFontSize = 16
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .resizable()
                                .frame(width: 12, height: 12)
                        }
                        .buttonStyle(.accessoryBarAction)
                    }
                    
                    Text("Text Example \(chatFontSize)pt")
                        .font(.system(size: CGFloat(chatFontSize)))
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .padding(Units.normalGap / 2)
                        .padding(.top, Units.normalGap * -0.8)
                }
                .clipShape(.rect(cornerRadius: Units.normalGap / 2))
            }
        }
        .padding()
    }
}

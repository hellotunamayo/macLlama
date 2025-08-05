//
//  CustomModelSelectPickerView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 8/2/25.
//
import SwiftUI

//MARK: Custom Picker
struct CutomModelSelectPickerView: View {
    
    @Binding var currentModel: String
    @Binding var modelList: [OllamaModel]
    
    @State private var isOverlayShowing: Bool = false
    
    let maxHeight: CGFloat = 250.0
    
    var body: some View {
        VStack {
            if #available(macOS 26.0, *) {
                ZStack {
                    Capsule().fill(.clear).glassEffect()
                    
                    Text(currentModel)
                        .greedyFrame(axis: .horizontal, alignment: .leading)
                        .padding(.horizontal)
                        .background(.windowBackground.opacity(0.0001))
                        .onTapGesture {
                            withAnimation {
                                isOverlayShowing.toggle()
                            }
                        }
                }
                .offset(y: -1)
                .frame(maxWidth: Units.appFrameMinWidth * 0.33, maxHeight: Units.normalGap * 1.8)
                .overlay {
                    if isOverlayShowing{
                        List(selection: $currentModel) {
                            ForEach(modelList, id: \.self) { model in
                                Text(model.name)
                                    .lineLimit(1)
                                    .greedyFrame(axis: .horizontal, alignment: .leading)
                                    .background(.windowBackground.opacity(0.0001))
                                    .padding(.vertical, Units.normalGap / 2)
                                    .listRowSeparator(.hidden)
                                    .onTapGesture {
                                        self.currentModel = model.name
                                        withAnimation {
                                            isOverlayShowing = false
                                        }
                                    }
                            }
                        }
                        .glassEffect(in: .rect(cornerRadius: Units.normalGap / 2))
                        .frame(height: self.maxHeight)
                        .offset(y: maxHeight * 0.58)
                    }
                }
            } else {
                Picker("Model", selection: $currentModel) {
                    Text("Select Model").selectionDisabled(true).tag("")
                    ForEach(modelList, id: \.self) { model in
                        Text(model.name)
                            .tag(model.name)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: Units.appFrameMinWidth * 0.45)
            }
        }
    }
}

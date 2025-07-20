//
//  SwiftUIView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 7/19/25.
//

import SwiftUI

struct PurposeButton: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isToggled: Bool
    let gesture: TapGesture = TapGesture()
    let labelString: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Units.normalGap / 2)
                .fill(self.isToggled ? Color.blue : Color.gray.opacity(0.2))
                .stroke(self.isToggled ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
            Label(self.labelString, systemImage: self.systemImage)
                .foregroundStyle(self.isToggled ? Color.white : Color.primary)
        }
        .frame(minWidth: 90, maxWidth: .infinity, idealHeight: 38, maxHeight: 48)
        .onTapGesture{
            withAnimation {
                self.action()
            }
        }
    }
}

struct FirstSuggestionView: View {
    @Binding var isPresented: Bool
    @Binding var step: Int
    @Binding var selectedPurpose: [SuggestionModelPurpose]
    
    @State private var isGeneral: Bool = false
    @State private var isWriting: Bool = false
    @State private var isCodeGenerating: Bool = false
    @State private var isVision: Bool = false
    @State private var isEtc: Bool = false
    @State private var isFormValid: Bool = false
    
    enum PurposeKey: String, CaseIterable {
        case general = "general"
        case writing = "writing"
        case codeGenerating = "code"
        case vision = "vision"
        case etc = "etc"
    }
    
    var body: some View {
        VStack {
            Text("What is your purpose?")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .padding(.bottom)
            
            ScrollView {
                VStack {
                    PurposeButton(isToggled: self.$isGeneral, labelString: "General Use", systemImage: "bubble") {
                        self.isGeneral.toggle()
                    }
                    PurposeButton(isToggled: self.$isWriting, labelString: "Writing", systemImage: "long.text.page.and.pencil") {
                        self.isWriting.toggle()
                    }
                    PurposeButton(isToggled: self.$isCodeGenerating, labelString: "Code Generation", systemImage: "chevron.left.forwardslash.chevron.right") {
                        self.isCodeGenerating.toggle()
                    }
                    PurposeButton(isToggled: self.$isVision, labelString: "Work with image", systemImage: "photo") {
                        self.isVision.toggle()
                    }
                    PurposeButton(isToggled: self.$isEtc, labelString: "Other", systemImage: "questionmark") {
                        self.isEtc.toggle()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, Units.normalGap / 4)
            }
            
            Spacer()
            
            HStack {
                Button {
                    self.isPresented.toggle()
                } label: {
                    Label("Close", systemImage: "xmark")
                        .padding(.horizontal)
                }
                .buttonStyle(.bordered)
                .controlSize(.extraLarge)
                
                Button {
                    self.selectedPurpose.removeAll()
                    
                    let purposes: [PurposeKey:Bool] = [
                        .general : self.isGeneral,
                        .writing : self.isWriting,
                        .codeGenerating : self.isCodeGenerating,
                        .vision : self.isVision,
                        .etc : self.isEtc
                    ]
                    
                    purposes.forEach { key, value in
                        switch key {
                            case .general:
                                if value { self.selectedPurpose.append(SuggestionModelPurpose.generalChat) }
                            case .writing:
                                if value { self.selectedPurpose.append(SuggestionModelPurpose.writing) }
                            case .codeGenerating:
                                if value { self.selectedPurpose.append(SuggestionModelPurpose.codeGeneration) }
                            case .vision:
                                if value { self.selectedPurpose.append(SuggestionModelPurpose.vision) }
                            case .etc:
                                if value { self.selectedPurpose.append(SuggestionModelPurpose.etcetera) }
                        }
                    }
                    
                    #if DEBUG
                    print(self.selectedPurpose)
                    #endif
                    
                    withAnimation {
                        self.step += 1
                    }
                } label: {
                    Label("Next", systemImage: "arrow.right")
                        .padding(.horizontal)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.extraLarge)
                .disabled(!isFormValid)
            }
        }
        .onChange(of: [self.isGeneral, self.isWriting, self.isCodeGenerating, self.isVision, self.isEtc]) { _, newValue in
            let countOfTrue = newValue.filter { $0 }.count > 0
            if countOfTrue {
                self.isFormValid = true
            } else {
                self.isFormValid = false
            }
        }
    }
}

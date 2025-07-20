//
//  ModelSuggestionView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 7/19/25.
//

import SwiftUI

enum SuggestionModelPurpose: String, CaseIterable {
    case generalChat , writing, codeGeneration, creativeJob, vision, etcetera
}

struct SuggestionModel: Identifiable, Hashable {
    let id: UUID = UUID()
    var purpose: [SuggestionModelPurpose]
    var modelName: String
    var fullName: String
    var modelParameterCount: UInt64
}

struct ModelSuggestionView: View {
    @Binding var isSheetPresent: Bool
    @State private var processorCount: UInt64?
    @State private var psysicalMemory: UInt64?
    @State private var cpuInfo: String?
    @State private var suggestionStep: Int = 0
    @State private var selectedPurpose: [SuggestionModelPurpose] = []
    
    let viewModel: ModelSuggestionViewModel = .init()
    let modelManagementViewModel: ModelManagementViewModel
    
    var body: some View {
        NavigationStack {
            VStack {
                switch self.suggestionStep{
                    case 0:
                        FirstSuggestionView(isPresented: self.$isSheetPresent, step: self.$suggestionStep,
                                            selectedPurpose: self.$selectedPurpose)
                    case 1:
                        SecondSuggestionView(selectedPurpose: self.$selectedPurpose, isShowing: self.$isSheetPresent,
                                             step: self.$suggestionStep, viewModel: self.viewModel,
                                             modelManagementViewModel: self.modelManagementViewModel)
                    default:
                        FirstSuggestionView(isPresented: self.$isSheetPresent, step: self.$suggestionStep,
                                            selectedPurpose: self.$selectedPurpose)
                }
            }
            .frame(minHeight: 400)
            .padding(.vertical)
            .navigationTitle("Model Suggestion")
        }
    }
}

//#Preview {
//    ModelSuggestionView(isSheetPresent: .constant(true))
//}

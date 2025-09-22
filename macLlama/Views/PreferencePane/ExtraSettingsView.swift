//
//  ExtraSettingsView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 8/15/25.
//

import SwiftUI

struct ExtraSettingsView: View {
    @State private var showGoogleAPI: Bool = false
    @State private var showGoogleCX: Bool = false
    @Binding var googleSearchAPIKey: String
    @Binding var googleSearchAPICX: String
    
    var body: some View {
        Form {
            Section(header: Text("Google Custom Search").padding(.bottom, Units.normalGap / 2)) {
                HStack {
                    if showGoogleAPI {
                        TextField(text: $googleSearchAPIKey, prompt: Text("Google Custom Search API Key")) {
                            Text("API Key")
                        }
                    } else {
                        SecureField(text: $googleSearchAPIKey, prompt: Text("Google Custom Search API Key")) {
                            Text("API Key")
                        }
                    }
                    
                    Button {
                        self.showGoogleAPI.toggle()
                    } label: {
                        Label("Show/Hide", systemImage: showGoogleAPI ? "eye.slash" : "eye")
                            .labelStyle(.iconOnly)
                    }
                }
                
                HStack {
                    if showGoogleCX {
                        TextField(text: $googleSearchAPICX, prompt: Text("Google Custom Search Engine ID (CX)")) {
                            Text("CX")
                        }
                    } else {
                        SecureField(text: $googleSearchAPICX, prompt: Text("Google Custom Search Engine ID (CX)")) {
                            Text("CX")
                        }
                    }
                    
                    Button {
                        self.showGoogleCX.toggle()
                    } label: {
                        Label("Show/Hide", systemImage: showGoogleCX ? "eye.slash" : "eye")
                            .labelStyle(.iconOnly)
                    }
                }
            }
            
            Divider()
            
            Spacer()
        }
        .padding()
    }
}

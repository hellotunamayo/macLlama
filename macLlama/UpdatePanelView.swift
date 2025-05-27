//
//  UpdatePanelView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/26/25.
//

import SwiftUI
import MarkdownUI

struct UpdatePanelView: View {
    @Binding var updateData: (version: String, htmlURL: String, body: String)
    @State private var isLatestVersion: Bool? = nil
    
    let githubService: GithubService = GithubService()
    
    var body: some View {
        VStack {
            if isLatestVersion ?? true {
                VStack {
                    Image("macLlama-profile")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .aspectRatio(contentMode: .fit)
                        .clipShape(Circle())
                        .padding(.trailing, 3)
                    
                    Text("You are using the latest version of macLlama.")
                        .font(.title)
                        .padding()
                }
                .frame(width: 600, height: 400)
            } else {
                VStack(alignment: .leading) {
                    HStack {
                        Image("macLlama-profile")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .aspectRatio(contentMode: .fit)
                            .clipShape(Circle())
                            .padding(.trailing, 3)
                        
                        Text("New macLlama is available!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding(.bottom, 10)
                    
                    Text("We’ve released a **new version of macLlama!** To enjoy the latest features and improvements, please update your app now.")
                        .font(.title3)
                        .padding(.bottom, 10)
                    
                    Divider()
                    
                    ScrollView {
                        VStack {
                            Markdown{
                                MarkdownContent(self.updateData.body)
                            }
                            .padding()
                        }
                    }
                    .frame(height: 500)
                    
                    Divider()
                    
                    Spacer()
                    
                    VStack {
                        Link(destination: URL(string: self.updateData.htmlURL) ?? URL(fileURLWithPath: "")) {
                            Label("Click here to update", systemImage: "safari")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.vertical)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(width: 500, height: 700)
                .padding()
            }
        }
        .task {
            do {
                if let checkUpdateResult = try await self.githubService.checkForUpdates() {
                    self.isLatestVersion = false
                    self.updateData = checkUpdateResult
                } else {
                    self.isLatestVersion = true
                }
            } catch {
                self.isLatestVersion = true
            }
        }
        
    }
}

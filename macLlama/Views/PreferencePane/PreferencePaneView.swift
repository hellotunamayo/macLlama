//
//  PreferencePaneView.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/21/25.
//

import SwiftUI

enum AppSettings {
    static let lastModel: String? = nil
    static let serverKillWithApp: Bool = false
    static let isAutoScrollEnabled: Bool = false
    static let chatFontSize: Int = 16
    static let promptSuffix: String = ""
    static let isAutoUpdateEnabled: Bool = true
    static let currentVersionNumber: String? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String //version number
    static let currentBuildNumber: String? = Bundle.main.infoDictionary?["CFBundleVersion"] as? String //bundle version
    static let lastUpdateCheckDate: Double = Date().timeIntervalSince1970
}

enum PreferenceTab {
    case general
}

struct PreferencePaneView: View {
    @AppStorage("serverKillWithApp") var serverKillWithApp: Bool = AppSettings.serverKillWithApp
    @AppStorage("chatFontSize") var chatFontSize: Int = AppSettings.chatFontSize
    @AppStorage("promptSuffix") var promptSuffix: String = AppSettings.promptSuffix
    @AppStorage("isAutoScrollEnabled") var isAutoScrollEnabled: Bool = AppSettings.isAutoScrollEnabled
    @AppStorage("isAutoUpdateEnabled") var isAutoUpdateEnabled: Bool = AppSettings.isAutoUpdateEnabled

    //For older version of macOS
    @State private var selectedTab: PreferenceTab = .general
    
    var body: some View {
        if #available(macOS 15.0, *) {
            TabView {
                Tab("General", systemImage: "gear") {
                    GeneralView(serverKillWithApp: $serverKillWithApp,
                                isAutoScrollEnabled: $isAutoScrollEnabled,
                                promptSuffix: $promptSuffix, isAutoUpdateEnabled: $isAutoUpdateEnabled)
                    .frame(width: 600, height: 400)
                }
                
                Tab("Typography", systemImage: "textformat") {
                    TypographyView(chatFontSize: $chatFontSize)
                        .frame(width: 600, height: 200)
                }
                
                Tab("Model Management", systemImage: "apple.intelligence") {
                    ModelManagementView()
                        .frame(width: 600, height: 700)
                }
            }
            .navigationTitle("macLlamas Preferences")
        } else {
            TabView {
                GeneralView(serverKillWithApp: $serverKillWithApp, isAutoScrollEnabled: $isAutoScrollEnabled,
                            promptSuffix: $promptSuffix, isAutoUpdateEnabled: $isAutoUpdateEnabled)
                    .tabItem {
                        Label("General", systemImage: "gear")
                    }
                    .tag(1)
                
                TypographyView(chatFontSize: $chatFontSize)
                    .tabItem {
                        Label("Typography", systemImage: "textformat")
                    }
                    .tag(2)
                
                ModelManagementView()
                    .tabItem {
                        Label("Model Management", systemImage: "apple.intelligence")
                    }
                    .frame(height: 500)
                    .tag(3)
            }
            .tabViewStyle(.automatic)
            .frame(maxWidth: 600)
        }
    }
}

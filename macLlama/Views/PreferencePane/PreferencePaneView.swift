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
    static let markdownTheme: String = MarkdownTheme.basic.rawValue
    static let hostProtocol: String = "http://"
    static let hostAddress: String = "localhost"
    static let hostPort: Int = 11434
    
    func getHostURL() -> String {
        return "\(AppSettings.hostAddress.isEmpty ? "localhost" : AppSettings.hostAddress):\(AppSettings.hostPort)"
    }
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
    @AppStorage("markdownTheme") var markdownTheme: String = AppSettings.markdownTheme
    @AppStorage("hostProtocol") var hostProtocol: String = AppSettings.hostProtocol
    @AppStorage("hostAddress") var hostAddress: String = AppSettings.hostAddress
    @AppStorage("hostPort") var hostPort: Int = AppSettings.hostPort

    //For older version of macOS
    @State private var selectedTab: PreferenceTab = .general
    
    var body: some View {
        if #available(macOS 15.0, *) {
            TabView {
                Tab("General", systemImage: "gear") {
                    GeneralView(serverKillWithApp: $serverKillWithApp,
                                isAutoScrollEnabled: $isAutoScrollEnabled,
                                promptSuffix: $promptSuffix, isAutoUpdateEnabled: $isAutoUpdateEnabled,
                                hostAddress: $hostAddress, hostPort: $hostPort, hostProtocol: $hostProtocol)
                    .frame(width: 600, height: 400)
                }
                
                Tab("Typography", systemImage: "textformat") {
                    TypographyView(chatFontSize: $chatFontSize, selectedMarkdownFormat: $markdownTheme)
                        .frame(width: 600, height: 400)
                }
                
                Tab("Model Management", systemImage: "apple.intelligence") {
                    ModelManagementView()
                        .frame(width: 600, height: 700)
                }
            }
            .navigationTitle("macLlama Preferences")
        } else {
            TabView {
                GeneralView(serverKillWithApp: $serverKillWithApp,
                            isAutoScrollEnabled: $isAutoScrollEnabled,
                            promptSuffix: $promptSuffix, isAutoUpdateEnabled: $isAutoUpdateEnabled,
                            hostAddress: $hostAddress, hostPort: $hostPort, hostProtocol: $hostProtocol)
                    .tabItem {
                        Label("General", systemImage: "gear")
                    }
                    .tag(1)
                
                TypographyView(chatFontSize: $chatFontSize, selectedMarkdownFormat: $markdownTheme)
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

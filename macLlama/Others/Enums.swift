//
//  Enums.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/31/25.
//

import Foundation
import MarkdownUI

enum MarkdownTheme: String, Hashable, CaseIterable {
    case basic = "Basic"
    case docc = "DocC"
    case github = "GitHub"
    
    static func getTheme(themeName: String) -> Theme {
        switch themeName {
            case "Basic":
                return Theme.basic
            case "DocC":
                return Theme.docC
            case "GitHub":
                return Theme.gitHub
            default:
                return Theme.basic
        }
    }
}

enum PreferenceTab {
    case general, typography, severManagement
    }

//
//  GithubService.swift
//  macLlama
//
//  Created by Minyoung Yoo on 5/26/25.
//

import Foundation

struct AppVersion: Decodable {
    let htmlURL: String
    let tagName: String
    let body: String
    
    enum CodingKeys: String, CodingKey {
        case body
        case htmlURL = "html_url"
        case tagName = "tag_name"
    }
}

actor GithubService {
    let currentVersion: String? = AppSettings.currentVersionNumber
//    let currentVersion: String? = "1.0.0" //for debug
    let currentBuildNumber: String? = AppSettings.currentBuildNumber
    var currentFullVersion: String {
        guard let currentVersion, let currentBuildNumber else {
            return "Unknown"
        }
        return "\(currentVersion)(\(currentBuildNumber))"
    }
    
    func checkForUpdates() async throws -> (version: String, htmlURL: String, body: String)? {
        let urlString = "https://api.github.com/repos/hellotunamayo/macLlama/releases/latest"
        
        do {
            guard let url = URL(string: urlString) else {
                throw URLError(.badURL)
            }
            let (data, response) = try await URLSession.shared.data(from: url)
            let httpURLResponse = response as! HTTPURLResponse
            
            switch httpURLResponse.statusCode {
                case 200..<300:
                    let characterSetToRemove = CharacterSet(charactersIn: "v")
                    let appVersion = try JSONDecoder().decode(AppVersion.self, from: data)
                    let appVersionNumber = appVersion.tagName.trimmingCharacters(in: characterSetToRemove)
//                    let appVersionNumber = "1.0.4(5)" //for debug
                    guard let currentVersion = self.currentVersion else {
                        throw NSError(domain: "", code: -1,
                                      userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve app version"])
                    }
                    let currentFullVersion = currentVersion + ("(\(currentBuildNumber ?? "0"))")
                    
                    //If the app is up to date, this is false
                    let isOutdated = appVersionNumber.compare(currentFullVersion, options: .numeric) == .orderedDescending
                    
                    #if DEBUG
                    debugPrint(appVersion.body)
                    debugPrint("isOutdated?: \(isOutdated) / remoteVersion: \(appVersionNumber): / currentVersion: \(currentFullVersion)")
                    #endif
                    
                    if isOutdated {
                        return (version: appVersion.tagName, htmlURL: appVersion.htmlURL, body: appVersion.body)
                    } else {
                        return nil
                    }
                default:
                    throw URLError(.badServerResponse)
            }
        } catch {
            debugPrint("Error while checking for updates: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func getBuildNumberFromTag(_ versionString: String) -> String? {
        // Remove "v" at the beginning
        var result = versionString.replacingOccurrences(of: "v", with: "", options: .caseInsensitive)
        
        // Remove version number (e.g., "1.0.0") - assumes it's digits and dots
        result = result.replacingOccurrences(of: "[0-9]+\\.[0-9]+\\.[0-9]+", with: "", options: .regularExpression)
        
        // Remove "(" and ")"
        result = result.replacingOccurrences(of: "\\(", with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: "\\)", with: "", options: .regularExpression)
        
        return result
    }
}

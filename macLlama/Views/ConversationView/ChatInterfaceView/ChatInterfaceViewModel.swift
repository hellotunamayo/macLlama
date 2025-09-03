//
//  ChatInterfaceViewModel.swift
//  macLlama
//
//  Created by Minyoung Yoo on 8/14/25.
//

import Foundation
import FoundationModels

@available(macOS 26.0, *)
@Generable
struct SummaryResult {
    @Guide(description: "This is the summary text of the search result.")
    var summaryText: String
}

actor ChatInterfaceViewModel {
    private let searchService = GoogleSearchService()
    
    func getWebResponse(from prompt: String) async -> (String,String)? {
        let actor = GoogleSearchService()
        do {
            let userPrompt: String = prompt
            guard let result = try await actor.fetchSearchResults(for: userPrompt) else { return nil }
            
            #if DEBUG
            print("User's prompt is: \(prompt)")
            print("Search Result from: \(result.items?[8].link ?? "No data")")
            print("-----")
            print(result.items?[0].snippet ?? "No data")
            print("-----")
            #endif
            
            guard let items = result.items,
                  let link = items[0].link,
                  let url = URL(string: link) else { return nil }
            guard let firstDataFromFirstURL = await actor.getUrlContents(from: url) else { return nil }
            
            let filteredString = await actor.extractAllContentFromTags(tags: ["h1", "p", "table", "td", "tr"], from: firstDataFromFirstURL)
            let tagStrippedString = filteredString.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            let whiteSpaceRemovedString = tagStrippedString.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            
            if #available(macOS 26.0, *) {
                let summaryResponse = try await self.summrizeSearchResult(userPrompt: userPrompt,
                                                                          content: whiteSpaceRemovedString)
                return (summaryResponse, result.items?[8].link ?? "No data")
            } else {
//                let maxLength: Int = 4_000
                let truncatedText = await self.truncateText(whiteSpaceRemovedString)
                return (truncatedText, result.items?[8].link ?? "No data")
            }
        } catch {
            debugPrint(error)
            return nil
        }
    }
    
    @available(macOS 26.0, *)
    private func summrizeSearchResult(userPrompt: String, content: String) async throws -> String {
        let maxLength: Int = 4_000
        var chunks: [String] = []
        var summrizedChunks: [SummaryResult] = []
        var startIndex: String.Index = content.startIndex
        
        while startIndex < content.endIndex {
            let endIndex = content.index(startIndex, offsetBy: maxLength, limitedBy: content.endIndex) ?? content.endIndex
            let chunk = String(content[startIndex..<endIndex])
            chunks.append(chunk)
            startIndex = endIndex
            if startIndex >= content.endIndex { break }
        }
        
        for i in 0..<chunks.count {
            let instructions: String = "Summarize the result of user's prompt: \(userPrompt)."
            let localSession: LanguageModelSession = LanguageModelSession(instructions: instructions)
            let summaryResult = try await localSession.respond(
                to: "Summrize this text. Focus on the main topic and key points.\n\nThe text is: \(chunks[i])",
                generating: SummaryResult.self
            )
            
            #if DEBUG
            debugPrint(summaryResult.content.summaryText)
            #endif
            
            summrizedChunks.append(summaryResult.content)
        }
        
        #if DEBUG
        debugPrint("-----------------------------")
        #endif
        
        let combinedSummary = summrizedChunks.map{ $0.summaryText }.joined(separator: "\n")
        
        #if DEBUG
        debugPrint(combinedSummary)
        #endif
        
        return combinedSummary
    }
    
    private func truncateText(_ text: String, maxLength: Int? = nil) async -> String {
        let maxLength: Int = maxLength ?? Int.max
        if text.count <= maxLength { return text }
        let endIndex = text.index(text.startIndex, offsetBy: max(0, maxLength - 1))
        return String(text[..<endIndex])
    }
}

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
    var summaryText: String
}

actor ChatInterfaceViewModel {
    private let searchService = GoogleSearchService()
    
    func summarizeWebResponse(from prompt: String) async -> String? {
        let actor = GoogleSearchService()
        do {
            let userPrompt: String = prompt
            guard let result = try await actor.fetchSearchResults(for: userPrompt) else { return nil }
            
#if DEBUG
            //            print("User's prompt is: \(prompt)")
            //            print("Search Result from: \(result.items?[8].link ?? "No data")")
            //            print("-----")
            //            print(result.items?[0].snippet ?? "No data")
            //            print("-----")
#endif
            
            guard let firstDataFromFirstURL = await actor.getUrlContents(from: URL(string: (result.items?[0].link)!)!) else { return nil }
            
            let filteredString = await actor.extractAllContentFromTags(tags: ["h1", "p", "table", "td", "tr"], from: firstDataFromFirstURL)
            let tagStrippedString = filteredString.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            let whiteSpaceRemovedString = tagStrippedString.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            
            if #available(macOS 26.0, *) {
                let summaryResponse = try await self.summrizeSearchResult(userPrompt: userPrompt,
                                                                          content: whiteSpaceRemovedString)
                return summaryResponse
            } else {
                let maxLength: Int = 1_000
                let truncatedText = await self.truncateText(whiteSpaceRemovedString, maxLength: maxLength)
                return truncatedText
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
        
        //Instructions for model
        let instructions: String = """
            Summarize the result of user's prompt "\(userPrompt)".
        """
        let modelSession = LanguageModelSession(instructions: instructions)
        
        var startIndex: String.Index = content.startIndex
        
        while startIndex < content.endIndex {
            let endIndex = content.index(startIndex, offsetBy: maxLength, limitedBy: content.endIndex) ?? content.endIndex
            let chunk = String(content[startIndex..<endIndex])
            chunks.append(chunk)
            startIndex = endIndex
            if startIndex >= content.endIndex { break }
        }
        
        for i in 0..<chunks.count {
            let localSession: LanguageModelSession = LanguageModelSession(instructions: instructions)
            let summaryResult = try await localSession.respond(
                to: "Summrize this text. Focus on the main topic and key points.\n\n\(chunks[i])",
                generating: SummaryResult.self
            )
            
            print(summaryResult.content.summaryText)
            summrizedChunks.append(summaryResult.content)
        }
        
        print("-----------------------------")
        
        let combinedSummary = summrizedChunks.map{ $0.summaryText }.joined(separator: "\n")
        
        //Summrize through FoundationModels
        //        let combinedSummary = await self.truncateText(summrizedChunks.joined(), maxLength: maxLength)
        let promptForSummarize: String = """
            You are a helpful assistant. Summarize the text below. Focus on the main topic and key points.\n\n\(combinedSummary)
        """
        let summaryResponse = try await modelSession.respond(
            to: promptForSummarize,
            generating: SummaryResult.self
        )
        print(summaryResponse.content.summaryText)
        return summaryResponse.content.summaryText
    }
    
    private func truncateText(_ text: String, maxLength: Int) async -> String {
        if text.count <= maxLength { return text }
        let endIndex = text.index(text.startIndex, offsetBy: max(0, maxLength - 1))
        return String(text[..<endIndex])
    }
}

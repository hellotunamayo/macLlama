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

@available(macOS 26.0, *)
@Generable
struct MostRelevantURL {
    @Guide(description: "This is most relavant web URL from google search.")
    var urlString: String
}

actor ChatInterfaceViewModel {
    private let searchService = GoogleSearchService()
    private let googleSearchActor = GoogleSearchService()
    
    func getWebResponse(from prompt: String) async -> (String,String)? {
        do {
            let userPrompt: String = prompt
            guard let result = try await googleSearchActor.fetchSearchResults(for: userPrompt) else { return nil }

            if #available(macOS 26.0, *) {
                //Apple Foundation Model Support
                let relevantLink = try await getMostRelevantURLString(userPrompt: prompt, searchResult: result)
                let relevantURL = URL(string: relevantLink)
                let firstDataFromFirstURL = await googleSearchActor.getUrlContents(from: relevantURL!) ?? ""
                let whiteSpaceRemovedString = await getWhiteSpaceRemovedText(content: firstDataFromFirstURL)
                
                let summaryResponse = try await self.summrizeSearchResult(userPrompt: userPrompt,
                                                                          content: whiteSpaceRemovedString)
                
                return (summaryResponse, relevantLink)
            } else {
                guard let items = result.items,
                      let link = items[0].link,
                      let url = URL(string: link) else { return nil }
                
                let firstDataFromFirstURL = await googleSearchActor.getUrlContents(from: url) ?? ""
                let whiteSpaceRemovedString = await getWhiteSpaceRemovedText(content: firstDataFromFirstURL)
                let truncatedText = await self.truncateText(whiteSpaceRemovedString)
                return (truncatedText, result.items?[8].link ?? "No data")
            }
        } catch {
            debugPrint(error)
            return nil
        }
    }
    
    private func getWhiteSpaceRemovedText(content: String) async -> String {
        let filteredString = await googleSearchActor.extractAllContentFromTags(tags: ["h1", "p", "table", "td", "tr"], from: content)
        let tagStrippedString = filteredString.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let whiteSpaceRemovedString = tagStrippedString.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return whiteSpaceRemovedString
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
    
    @available(macOS 26.0, *)
    private func getMostRelevantURLString(userPrompt: String, searchResult: SearchResult) async throws -> String {
        let foundationModelPrompt: String = "Select the most relevant URL from the provided URLs `\(searchResult)` based on the user prompt `\(userPrompt)`. Respond with only the URL text."
        var urls: [String] = []
        searchResult.items?.forEach { result in
            if let url = result.link {
                urls.append(url)
            }
        }
        let session = LanguageModelSession()
        let selectedURL = try await session.respond(to: foundationModelPrompt, generating: MostRelevantURL.self)
        
        #if DEBUG
        debugPrint("Most relevant URL is : \(selectedURL.content.urlString)")
        debugPrint("Search Result's url: \(urls)")
        #endif
        
        return selectedURL.content.urlString
    }
    
    private func truncateText(_ text: String, maxLength: Int? = nil) async -> String {
        let maxLength: Int = maxLength ?? Int.max
        if text.count <= maxLength { return text }
        let endIndex = text.index(text.startIndex, offsetBy: max(0, maxLength - 1))
        return String(text[..<endIndex])
    }
}

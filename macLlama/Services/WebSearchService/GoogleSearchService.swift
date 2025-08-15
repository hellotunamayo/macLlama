//
//  GoogleSearchService.swift
//  macLlama
//
//  Created by Minyoung Yoo on 8/13/25.
//
import Foundation
import FoundationModels

@available(macOS 26.0, *)
@Generable
struct RecommendedQuery {
    @Guide(description: "This is the query user want to search for.")
    var searchQuery: String
}

struct SearchResult: Decodable, Sendable {
    let items: [SearchResultItem]?
}

struct SearchResultItem: Decodable, Sendable {
    let title: String?
    let snippet: String?
    let formattedUrl: String?
    let link: String?
}

actor GoogleSearchService {
    
    func fetchSearchResults(for queryString: String) async throws -> SearchResult? {
        let apiKey = UserDefaults.standard.string(forKey: "googleSearchAPIKey") ?? ""
        let cxKey = UserDefaults.standard.string(forKey: "googleSearchAPICX") ?? ""
        let endpoint = "https://www.googleapis.com/customsearch/v1?key=\(apiKey)&cx=\(cxKey)"
        var suggestedSearchQuery: String
        #if DEBUG
        debugPrint("Google Search API Endpoint: \(endpoint)")
        #endif
        
        if #available(macOS 26.0, *) {
            suggestedSearchQuery = await self.getSearchKeyword(from: queryString) ?? queryString
        } else {
            suggestedSearchQuery = queryString
        }
        
        #if DEBUG
        debugPrint("Suggested Search Query: \(suggestedSearchQuery)")
        #endif
        
        do {
            let requestString = endpoint + "&q=\(suggestedSearchQuery)"
            guard let url = URL(string: requestString) else { throw URLError(.badURL) }
            let (data, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("HTTP status code: \(httpResponse.statusCode)")
                return nil
            }
            return try JSONDecoder().decode(SearchResult.self, from: data)
        } catch {
            print(error)
            throw error
        }
    }
    
    @available(macOS 26.0, *)
    private func getSearchKeyword(from userPrompt: String) async -> String? {
        let session = LanguageModelSession()
        do {
            let prompt = """
            You are a specialized assistant designed to optimize Google Advanced Search queries. You are connected to a Google Advanced Search API, and your goal is to generate effective search terms that will retrieve the most relevant and high-quality results. The user’s original prompt is: \(userPrompt)
            """
            let result: String = try await session.respond(
                to: prompt,
                generating: RecommendedQuery.self
            ).content.searchQuery
            
            return result
            
        } catch {
            #if DEBUG
            debugPrint("Failed to generate recommended query: \(error)")
            #endif
            return nil
        }
    }
    
    func getUrlContents(from url: URL) async -> String? {
        guard let stringData = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        return stringData
    }
    
    func stripHTMLTags(tags: [String], from originalString: String) -> String {
        var result = originalString
        
        // Remove opening/closing tags with content
        for tag in tags {
            let escapedTag = NSRegularExpression.escapedPattern(for: tag)
            let pattern = "<\\s*\(escapedTag)(?:\\s[^>]*)?>(.*?)<\\s*/\(escapedTag)\\s*>"
            
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
                let stringRange = NSRange(location: 0, length: result.utf16.count)
                result = regex.stringByReplacingMatches(in: result, options: [], range: stringRange, withTemplate: "")
            } catch {
                print("regexError for tag \(tag): \(error)")
            }
        }
        
        // Remove self-closing tags
        for tag in tags {
            let escapedTag = NSRegularExpression.escapedPattern(for: tag)
            let pattern = "<\\s*\(escapedTag)(?:\\s[^>]*)?/?>"
            
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let stringRange = NSRange(location: 0, length: result.utf16.count)
                result = regex.stringByReplacingMatches(in: result, options: [], range: stringRange, withTemplate: "")
            } catch {
                print("regexError for self-closing tag \(tag): \(error)")
            }
        }
        
        return result
    }
    
    func extractAllContentFromTags(tags: [String], from originalString: String) -> String {
        var result = ""
        
        for tag in tags {
            // Handle case sensitivity and various HTML formats
            let escapedTag = NSRegularExpression.escapedPattern(for: tag)
            // More flexible pattern to handle various whitespace and attributes
            let pattern = "<\\s*\(escapedTag)(?:[^>]*?)?>(.*?)<\\s*/\(escapedTag)\\s*>"
            
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
                let stringRange = NSRange(location: 0, length: originalString.utf16.count)
                
                let matches = regex.matches(in: originalString, options: [], range: stringRange)
                
                for match in matches {
                    if match.numberOfRanges >= 2 { // Make sure we have at least 2 ranges (0=full match, 1=content)
                        if let range = Range(match.range(at: 1), in: originalString) {
                            let content = String(originalString[range])
                            result += "\(content.trimmingCharacters(in: .whitespacesAndNewlines))\n\n"
                        }
                    }
                }
            } catch {
                print("regexError for tag \(tag): \(error)")
            }
        }
        
        return result
    }
}

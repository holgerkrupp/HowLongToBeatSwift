import Foundation

class HLTBExtractor {
     let baseURL = "https://howlongtobeat.com/"
    
    
    func fetchAPIInfo() async throws -> (String?, String?) {
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }

        print(url.absoluteString)

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let html = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "FetchError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode HTML"])
        }

        // Find script URL containing "_app-"
        guard let scriptURL = self.extractScriptURL(from: html) else {
            throw NSError(domain: "FetchError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No script URL found"])
        }

        guard let scriptContent = try await self.fetchScriptContent(scriptURL) else {
            throw NSError(domain: "FetchError", code: 3, userInfo: [NSLocalizedDescriptionKey: "No script content found"])
        }

        let apiKey = self.extractAPIKey(from: scriptContent)
        let searchURL = self.extractSearchUrl(from: scriptContent, for: apiKey ?? "")

        print("key: \(apiKey ?? "none"), url: \(searchURL ?? "none")")

        return (apiKey, searchURL)
    }

    
    private  func extractScriptURL(from html: String) -> String? {
        let pattern = #"<script[^>]+src=["']([^"']*?_app-[^"']+)["']"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)) {
            let range = Range(match.range(at: 1), in: html)
            return range.map { baseURL + html[$0] }
        }
        return nil
    }
    
    private func fetchScriptContent(_ scriptURL: String) async throws -> String? {
        guard let url = URL(string: scriptURL) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)

        return String(data: data, encoding: .utf8)
    }
    
    
    
    func extractAPIKey(from scriptContent: String) -> String? {
        // Test 1 - The API Key is in the user id in the request JSON
        let userIdPattern = #"users\s*:\s*{\s*id\s*:\s*"([^"]+)""#
        if let matches = findMatches(in: scriptContent, pattern: userIdPattern, captureGroups: true), !matches.isEmpty {
            return matches.joined()
        }
        
        // Test 2 - The API Key is in format fetch("/api/[word here]/".concat("X").concat("Y")...)
        let concatPattern = #"/api/\w+/\"(?:\.concat\("[^"]*"\))*"#
        if let matches = findMatches(in: scriptContent, pattern: concatPattern, captureGroups: false), !matches.isEmpty {
            let components = matches.joined().components(separatedBy: ".concat").dropFirst()
            let cleanedComponents = components.map {
                $0.replacingOccurrences(of: #"["()\[\]"]"#, with: "", options: .regularExpression)
            }
            return cleanedComponents.joined()
        }
        
        // Unable to find :(
        return nil
    }

    private func findMatches(in text: String, pattern: String, captureGroups: Bool) -> [String]? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsText = text as NSString
        let results = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
        
        return results?.compactMap { result in
            if captureGroups, result.numberOfRanges > 1 {
                return nsText.substring(with: result.range(at: 1)) // Extract first capture group
            } else {
                return nsText.substring(with: result.range) // Extract full match
            }
        }
    }
    

    
    private func extractSearchUrl(from scriptContent: String, for apikey: String) -> String? {
        // Define the regular expression pattern
        let pattern = #"fetch\(\s*["'](\/api\/[^"']*)["']((?:\s*\.concat\(\s*["']([^"']*)["']\s*\))+)"#
        
        // Create a regular expression object
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return nil
        }
        
        // Perform the regex matching
        let matches = regex.matches(in: scriptContent, options: [], range: NSRange(scriptContent.startIndex..., in: scriptContent))
        
        for match in matches {
            if let endpointRange = Range(match.range(at: 1), in: scriptContent),
               let concatCallsRange = Range(match.range(at: 2), in: scriptContent) {
                
                // Extract the endpoint
                let endpoint = String(scriptContent[endpointRange])
                
                // Extract all concatenated strings using another regex
                let concatPattern = #"\.concat\(\s*["']([^"']*)["']\s*\)"#
                guard let concatRegex = try? NSRegularExpression(pattern: concatPattern) else {
                    return nil
                }
                
              //  let concatMatches = concatRegex.matches(in: String(scriptContent[concatCallsRange]), options: [], range: NSRange(scriptContent[concatCallsRange].startIndex..., in: scriptContent))
                
                
                let extractedSubstring = String(scriptContent[concatCallsRange])
                print("endpoint: \(endpoint) - substring: \(extractedSubstring)")
                let concatMatches = concatRegex.matches(in: extractedSubstring, options: [], range: NSRange(location: 0, length: extractedSubstring.utf8.count))
                
                let concatenatedString = concatMatches.compactMap { match -> String? in
                    if let range = Range(match.range(at: 1), in: extractedSubstring) {
                        return String(extractedSubstring[range])
                    }
                    return nil
                }.joined()
                

                // Check if the concatenated string matches the API key
                if concatenatedString == apikey {
                    return endpoint
                }
            }
        }
        
        // Unable to find
        return nil
    }
    
 
}

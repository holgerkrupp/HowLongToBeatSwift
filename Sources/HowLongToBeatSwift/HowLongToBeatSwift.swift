
import Foundation


public class HLTBRequest{
    

    let userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"
 

    public var request:URLRequest
    
    public enum DataFetchError: Error {
        case noDataReceived
        case networkError(Error)
        case invalidResponse
        case decodingError(Error)
        case unexpectedHTTPStatusCode(Int)
        
        var localizedDescription: String {
            switch self {
                
            case .networkError(let message):
                return String(format: "Network error: %@", message.localizedDescription)
            case .noDataReceived:
                return String(localized: "No data received from the server")
            case .invalidResponse:
                return String(localized: "Invalid response from the server")
            case .decodingError(let message):
                return String(format: "Error decoding data: %@", message.localizedDescription)
            case .unexpectedHTTPStatusCode(let statusCode):
                return String(format: "Unexpected HTTP status code: %@", statusCode.description)
            }
        }
    }

    
    public init() async{


        var searchurl: URL = URL(string: "https://www.howlongtobeat.com")!
        
        do {
            let (apiKey, searchURL) = try await HLTBExtractor().fetchAPIInfo()
            
                print("API Key: \(apiKey ?? "none"), Search URL: \(searchURL ?? "none")")
            searchurl = searchurl.appendingPathComponent(searchURL ?? "")
         
               
             searchurl = searchurl.appending(path: apiKey ?? "")
                
               
            
            print(searchurl.absoluteString)
            } catch {
                print("Error fetching API info: \(error)")
            }


       
        
       
        request = URLRequest(url: searchurl)
   
        request.httpMethod = "POST"
       request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("https://howlongtobeat.com", forHTTPHeaderField: "Referer")
    //    request.addValue("https://howlongtobeat.com", forHTTPHeaderField: "origin")
       
    }
    
    
    public func search(searchTerm: String, extactMatch:Bool = true) async throws -> [HowLongToBeatGame] {
        
        
        
        let postData = """
                        
                        
                        {
                            "searchType": "games",
                            "searchTerms": [
                                    "\(searchTerm)"
                            ],
                            "searchPage": 1,
                            "size": 20,
                            "searchOptions": {
                                "games": {
                                    "userId": 0,
                                    "platform": "",
                                    "sortCategory": "popular",
                                    "rangeCategory": "main",
                                    "rangeTime": {
                                        "min": 0,
                                        "max": 0
                                    },
                                    "gameplay": {
                                        "perspective": "",
                                        "flow": "",
                                        "genre": "",
                                        "difficulty": ""
                                    },
                                    "rangeYear": {
                                        "max": "",
                                        "min": ""
                                    },
                                    "modifier": ""
                                },
                                "users": {
                                    "sortCategory": "postcount"
                                },
                                "lists": {
                                    "sortCategory": "follows"
                                },
                                "filter": "",
                                "sort": 0,
                                "randomizer": 0
                            },
                            "useCache": true
                        }
                        
                        """
        request.httpBody = postData.data(using: .utf8)
        
        dump(request)
        
        let (data, response) = try await URLSession.shared.data(for: request)
 
     guard let httpResponse = response as? HTTPURLResponse else {
            throw DataFetchError.invalidResponse
        }
        
        // Check if the response status code is successful
        guard (200...299).contains(httpResponse.statusCode) else {
            throw DataFetchError.unexpectedHTTPStatusCode(httpResponse.statusCode)
        }
        
        // Check if data is received
        guard !data.isEmpty else {
            throw DataFetchError.noDataReceived
        }
        
        _ = String(data: data, encoding: .utf8)



        
            do {
                let decoder = JSONDecoder()
                let parsedData = try decoder.decode(JSONData.self, from: data)
                // Access parsed data here
                let games = parsedData.data
                if games.count > 0{
                    
                    
                    // Now you have an array of Game objects
                    print("Number of games: \(games.count) - for searchTerm: \(searchTerm)")
                    
                    // You can iterate through each game and access its properties
                    for game in games {
                        print("Game ID: \(game.game_id), Name: \(game.game_name), Release: \(game.release_world.formatted())")
                        // Access other properties as needed
                    }
                    
                    var filtered:[HowLongToBeatGame] = []
                    
                    if extactMatch{
                        filtered = games.filter { game in
                            game.game_name == searchTerm ||
                            game.game_alias == searchTerm
                        }
                    }
                    
                    print("Number of filtered games: \(filtered.count) - for searchTerm: \(searchTerm)")
                    
                    // You can iterate through each game and access its properties
                    for game in filtered {
                        print("Filtered: Game ID: \(game.game_id), Name: \(game.game_name), Release: \(game.release_world.formatted())")
                        // Access other properties as needed
                    }
                    
                    
                    return filtered.count > 0 ? filtered : games
                }else if searchTerm.contains(":"){
                    
                    // This is not sustainable, but a current workaround. Some games are listed with a different name in HLTB. For example King of Fighters XIII: Global Match does not contain the : in the HLTB name. Therefore I'm removing the : from games if no result was found previously. There could be other characters that need this treatment.
                    print("else remove :")
                    let changedSearch = searchTerm.replacingOccurrences(of: ":", with: "")
                    let newresult = try await search(searchTerm: changedSearch, extactMatch: true)
                    print("return")
                    dump(newresult)
                    return newresult
                }
                else {
                    return []
                }
            } catch {
                throw DataFetchError.decodingError(error)
            }
            
        }
    
    
}
struct HTMLRequests {
    static let BASE_URL = "https://www.howlongtobeat.com/"
    
    static func getTitleRequestHeaders() -> [String: String] {
        return ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36"]
    }
}

func asyncSendWebsiteRequestGetCode(parseAllScripts: Bool) async -> String? {
    let headers = HTMLRequests.getTitleRequestHeaders()
    
    guard let url = URL(string: HTMLRequests.BASE_URL) else {
        return nil
    }
    
    // Create a URLRequest and add headers
    var request = URLRequest(url: url)
    for (key, value) in headers {
        request.addValue(value, forHTTPHeaderField: key)
    }
    
    // Send the initial GET request to the website
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            // Convert the response data to a string
            let html = String(data: data, encoding: .utf8) ?? ""
            
            // Find all <script> tags with src attribute using simple string parsing
            let scriptTags = extractScriptSrcs(from: html)
            
            // Filter or use all script URLs depending on the `parseAllScripts` flag
            var scriptSrcs: [String] = []
            if parseAllScripts {
                scriptSrcs = scriptTags
            } else {
                scriptSrcs = scriptTags.filter { $0.contains("_app-") }
            }
            
            // Loop through each script URL and fetch the content
            for scriptSrc in scriptSrcs {
                let scriptURL = HTMLRequests.BASE_URL + scriptSrc
                
                // Create a request for the script
                guard let scriptRequestURL = URL(string: scriptURL) else { continue }
                var scriptRequest = URLRequest(url: scriptRequestURL)
                for (key, value) in headers {
                    scriptRequest.addValue(value, forHTTPHeaderField: key)
                }
                
                let (scriptData, scriptResponse) = try await URLSession.shared.data(for: scriptRequest)
                if let scriptHttpResponse = scriptResponse as? HTTPURLResponse, scriptHttpResponse.statusCode == 200 {
                    let scriptText = String(data: scriptData, encoding: .utf8) ?? ""
                    
                    // Regular expression to find the API key pattern
                    let pattern = #""/api/search/".concat\("([a-zA-Z0-9]+)"\)"#
                    if let regex = try? NSRegularExpression(pattern: pattern) {
                        let nsrange = NSRange(scriptText.startIndex..<scriptText.endIndex, in: scriptText)
                        if let match = regex.firstMatch(in: scriptText, options: [], range: nsrange) {
                            if let range = Range(match.range(at: 1), in: scriptText) {
                                let key = String(scriptText[range])
                                return key // Return the first found key
                            }
                        }
                    }
                }
            }
        }
    } catch {
        print("Error: \(error)")
    }
    
    return nil
}

// Helper function to extract script URLs from HTML using basic string manipulation
func extractScriptSrcs(from html: String) -> [String] {
    var scriptSrcs: [String] = []
    
    // Find all <script> tags and their src attributes
    let scriptTagPattern = #"<script[^>]+src\s*=\s*['"]([^'"]+)['"]"#
    if let regex = try? NSRegularExpression(pattern: scriptTagPattern, options: []) {
        let nsrange = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: nsrange)
        
        for match in matches {
            if let range = Range(match.range(at: 1), in: html) {
                let src = String(html[range])
                scriptSrcs.append(src)
            }
        }
    }
    
    return scriptSrcs
}

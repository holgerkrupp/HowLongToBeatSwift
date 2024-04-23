
import Foundation


public class HLTBRequest{
    
     let endpoint = "https://www.howlongtobeat.com/api/search"
    
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

    
   public init(){
        let urlComponents = NSURLComponents(string: endpoint)!
        
        // Create the URL request
        guard let url = urlComponents.url else {
            print("Invalid URL")
            exit(1)
        }
        
        request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("https://howlongtobeat.com", forHTTPHeaderField: "referer")
        request.addValue("https://howlongtobeat.com", forHTTPHeaderField: "origin")
    }
    
    
    public func search(searchTerm: String, extactMatch:Bool = true) async throws -> [HowLongToBeatGame] {
        
        
        
        let postData = """
                        {
                            "searchType": "games",
                            "searchTerms": [
                                "\(searchTerm)"
                            ],
                            "size" : 1000
                        }
                        """
        request.httpBody = postData.data(using: .utf8)
        
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
        
        let htmlString = String(data: data, encoding: .utf8)
     //   dump(htmlString)
      //  if let jsonData = htmlString?.data(using: .utf8)
            do {
                let decoder = JSONDecoder()
                let parsedData = try decoder.decode(JSONData.self, from: data)
                // Access parsed data here
                let games = parsedData.data
                
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
            } catch {
                throw DataFetchError.decodingError(error)
            }
            
        }
    
    
}

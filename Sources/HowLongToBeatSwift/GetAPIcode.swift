import Foundation

/// The short lived credentials the search endpoint expects.
/// `token` goes into the `x-auth-token` header, `hpKey`/`hpVal` go into the
/// `x-hp-key`/`x-hp-val` headers *and* into the request body as an extra field.
struct HLTBSecurityToken {
    let token: String
    let hpKey: String
    let hpVal: String
}

class HLTBExtractor {
    let baseURL = "https://howlongtobeat.com"

    /// The site used to hide the search endpoint inside its JS bundle. It now hands out
    /// a per-session token from `/api/bleed/init` instead, so there is nothing to scrape.
    func fetchSecurityToken(userAgent: String) async throws -> HLTBSecurityToken {
        // The token is bound to the timestamp, so it has to be part of the query.
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        guard let url = URL(string: "\(baseURL)/api/bleed/init?t=\(timestamp)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(baseURL, forHTTPHeaderField: "Referer")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "FetchError", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Could not fetch search token"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["token"] as? String,
              let hpKey = json["hpKey"] as? String,
              let hpVal = json["hpVal"] as? String else {
            throw NSError(domain: "FetchError", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Unexpected token payload"])
        }

        return HLTBSecurityToken(token: token, hpKey: hpKey, hpVal: hpVal)
    }
}

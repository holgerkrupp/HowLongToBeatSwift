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

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            // The host was unreachable at all - keep the underlying error, it says whether
            // this was DNS, TLS or a timeout.
            throw NSError(domain: "FetchError", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Could not reach \(baseURL): \(error.localizedDescription)",
                                     NSUnderlyingErrorKey: error])
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "FetchError", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Could not fetch search token: response was not HTTP"])
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Without the status code and body a CI failure here is undiagnosable: a 403
            // (the runner is being blocked) and a 404 (the endpoint moved again) need
            // very different fixes.
            throw NSError(domain: "FetchError", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Could not fetch search token: HTTP \(httpResponse.statusCode) from \(url.absoluteString). Body: \(HLTBExtractor.bodySnippet(data))",
                                     "statusCode": httpResponse.statusCode])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["token"] as? String,
              let hpKey = json["hpKey"] as? String,
              let hpVal = json["hpVal"] as? String else {
            throw NSError(domain: "FetchError", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Unexpected token payload: \(HLTBExtractor.bodySnippet(data))"])
        }

        return HLTBSecurityToken(token: token, hpKey: hpKey, hpVal: hpVal)
    }

    /// A short, log-safe excerpt of a response body.
    private static func bodySnippet(_ data: Data, limit: Int = 512) -> String {
        guard let text = String(data: data.prefix(limit), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return "<\(data.count) bytes, not UTF-8 text>"
        }
        return data.count > limit ? "\(text)… (\(data.count) bytes total)" : text
    }
}

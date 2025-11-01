import XCTest
@testable import HowLongToBeatSwift

final class HowLongToBeatSwiftTests: XCTestCase {
    func testSMB3() async throws {
       
        let searchName = "Super Mario Bros. 3"
        
        let hltb = await HLTBRequest()
        do{
            let games = try await hltb.search(searchTerm: searchName)
            dump(games)
            XCTAssertFalse(games.isEmpty, "Expected at least one result for \(searchName), but got 0.")
        }catch{
            XCTFail("Search threw an unexpected error: \(error)")
        }
        
        
    }
}

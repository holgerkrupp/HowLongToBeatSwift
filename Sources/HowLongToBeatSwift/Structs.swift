//
//  File.swift
//  
//
//  Created by Holger Krupp on 27.03.24.
//

import Foundation

public struct HowLongToBeatGame: Codable {
    public let game_id: Int
    public let game_name: String
    let game_name_date: Int
    public let game_alias: String
    let game_type: String
    let game_image: String
    let comp_lvl_combine: Int
    let comp_lvl_sp: Int
    let comp_lvl_co: Int
    let comp_lvl_mp: Int
    let comp_lvl_spd: Int
    let comp_main: Int
    let comp_plus: Int
    let comp_100: Int
    let comp_all: Int
    let comp_main_count: Int
    let comp_plus_count: Int
    let comp_100_count: Int
    let comp_all_count: Int
    let invested_co: Int
    let invested_mp: Int
    let invested_co_count: Int
    let invested_mp_count: Int
    let count_comp: Int
    let count_speedrun: Int
    let count_backlog: Int
    let count_review: Int
    let review_score: Int
    let count_playing: Int
    let count_retired: Int
    let profile_dev: String
    let profile_popular: Int
    let profile_steam: Int
    public let profile_platform: String
    public let release_world: Int
    // Add other properties as needed
    
    public var playTimes: [GameMode: Double] {
        return [
            .mainStory: Double(comp_main),
            .mainPlusExtras: Double(comp_plus),
            .completionist: Double(comp_100)
            // Add other properties as needed
        ]
    }
    

}

public struct JSONData: Codable {
    let color: String
    let title: String
    let category: String
    let count: Int
    let pageCurrent: Int
    let pageTotal: Int
    let pageSize: Int
    let data: [HowLongToBeatGame]
    let userData: [String]
    let displayModifier: String?
    // Add other properties as needed
    }

public enum GameMode: String {
    case mainStory = "Main Story"
    case mainPlusExtras = "Main + Extras"
    case completionist = "Completionist"
    case singlePlayer = "Single-Player"
    case solo = "Solo"
    case coOp = "Co-Op"
    case versus = "Vs."
    
    public var localizedDescription: String {
        // You can use NSLocalizedString or your preferred localization method here
        switch self {
        case .mainStory: return String(localized: "Main Story")
        case .mainPlusExtras: return String(localized:"Main + Extras", comment: "")
        case .completionist: return String(localized: "Completionist", comment: "")
        case .singlePlayer: return String(localized: "Single-Player", comment: "")
        case .solo: return String(localized: "Solo", comment: "")
        case .coOp: return String(localized: "Co-Op", comment: "")
        case .versus: return String(localized: "Vs.", comment: "")
        }
    }
}

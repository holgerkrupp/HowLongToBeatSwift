A simple package to read data from HowLongToBeat.com

## How to use

Create a instance of HLTBRequest() and perform search(searchTerm: String, extactMatch:Bool = true) on it using the Name of he Game

```swift
            let hltb = await HLTBRequest()
            do{
                let games = try await hltb.search(searchTerm: searchName)
            }catch{
                print(error)
            }
```

the return will be an array of games that fit the search term with their playtimes for different playmodes. If exactMatch is kept unchanged (= true), the list of games will be filtered to contain only the ones where the Game title is an exact match to the search Term. Times are given as Seconds.

```
  ▿ HowLongToBeatSwift.HowLongToBeatGame
    - game_id: 152370
    - game_name: "The Legend of Zelda: Echoes of Wisdom"
    - game_name_date: 0
    - game_alias: ""
    - game_type: "game"
    - game_image: "152370_The_Legend_of_Zelda_Echoes_of_Wisdom.jpg"
    - comp_lvl_combine: 0
    - comp_lvl_sp: 1
    - comp_lvl_co: 0
    - comp_lvl_mp: 0
    - comp_main: 73496
    - comp_plus: 92856
    - comp_100: 114520
    - comp_all: 95345
    - comp_main_count: 65
    - comp_plus_count: 142
    - comp_100_count: 91
    - comp_all_count: 298
    - invested_co: 0
    - invested_mp: 0
    - invested_co_count: 0
    - invested_mp_count: 0
    - count_comp: 428
    - count_speedrun: 0
    - count_backlog: 578
    - count_review: 232
    - review_score: 85
    - count_playing: 467
    - count_retired: 5
    - profile_popular: 2929
    - release_world: 2024
```

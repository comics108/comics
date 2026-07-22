//
//  YoutubeLinksContainer.swift
//  Mahabharata
//
//  Created by Aleksey Shevchenko on 03.10.2022.
//  Copyright © 2022 Iron Water Studio. All rights reserved.
//

extension YoutubeLinksContainer {
    struct Seasons {
        static var theAmbasSwearBook1: Int = 1
        static var littleKrishnaAndDemonsBook1 = 5
        static var shortStoriesFromMahabharata = 6
    }
}

struct YoutubeLinksContainer {
    private var dict: [Int: [Int: String]] = [:]
    init() {
        dict[Seasons.theAmbasSwearBook1] = theAmbasSwearBook1Season
        dict[Seasons.littleKrishnaAndDemonsBook1] = littleKrishnaAndDemonsBook1Season
        dict[Seasons.shortStoriesFromMahabharata] = shortStoriesFromMahabharataSeason
    }
}

extension YoutubeLinksContainer {
    var theAmbasSwearBook1Season: [Int: String] {
        [
            95: "https://www.youtube.com/watch?v=U_NGGTWwlCA",
            2: "https://www.youtube.com/watch?v=_-ygbi8M5GA",
            3: "https://www.youtube.com/watch?v=JQx9Vol63tg",
            4: "https://www.youtube.com/watch?v=herOHgAHB4Q",
            5: "https://www.youtube.com/watch?v=y4ABjmFenCY",
            6: "https://www.youtube.com/watch?v=UHowQ6oMHtY",
            7: "https://www.youtube.com/watch?v=mCSEg_EqGy8",
            8: "https://www.youtube.com/watch?v=pi-mWY8pF4E",
            9: "https://www.youtube.com/watch?v=eJQm4HYlESM",
            10: "https://www.youtube.com/watch?v=zxi8palW32A",
            11: "https://www.youtube.com/watch?v=rixnDjfq4F0",
            12: "https://www.youtube.com/watch?v=M_58XOrSoUY",
            13: "https://www.youtube.com/watch?v=E2MldAgz7e0",
            14: "https://www.youtube.com/watch?v=pCOAsxsNLhM",
            15: "https://www.youtube.com/watch?v=vQf6hEi_-rc",
            16: "https://www.youtube.com/watch?v=o9PStkHmmBU",
            17: "https://www.youtube.com/watch?v=kddnqLZuLK4"
        ]
    }
    
    var littleKrishnaAndDemonsBook1Season: [Int: String] {
        [
            35: "https://www.youtube.com/watch?v=Luj2ECwBbfI",
            36: "https://www.youtube.com/watch?v=dHjlhk8EXIE",
            38: "https://www.youtube.com/watch?v=xwLaHx-84iI",
            39: "https://www.youtube.com/watch?v=tXAKkd43d94",
        ]
    }
    
    var shortStoriesFromMahabharataSeason: [Int: String] {
        [
            37: "https://www.youtube.com/watch?v=XpMhzbCCIqw",
        ]
    }
}

extension YoutubeLinksContainer {
    func youtubeLink(_ seasonId: Int, _ episodeId: Int) -> String? {
        guard let seasonDict = dict[seasonId], let episodeLink = seasonDict[episodeId] else { return nil }
        return episodeLink
    }
}

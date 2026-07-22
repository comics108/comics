//
//  SeasonsViewController+ViewState.swift
//  Mahabharata
//
//  Created by Aleksey Shevchenko on 17.09.2022.
//  Copyright © 2022 Iron Water Studio. All rights reserved.
//

extension SeasonsViewController {
    enum SeasonsSource {
        case cache
        case server
    }
}

extension SeasonsViewController {
    struct ViewState {
        var delay: DispatchTime { return .now() + 8 }
        var seasonsSource: SeasonsSource?
        var seasons: [Season]
        var seasonsToShow: [Season] {
            seasons
                .filter({ !$0.episodes.isEmpty })
        }
        var episodes: [Episode] {
            seasonsToShow
                .flatMap({ $0.episodes })
                .reversed()
        }
        var nextEpisode: Episode?
        var loadStatus: LoadStatus

        let formatter: NumberFormatter = .currencyFormatter()
        var headerTitle: String { Local("Seasons.Header.Title") }
    }
}

extension SeasonsViewController.ViewState {
    static var empty: SeasonsViewController.ViewState {
        return .init(
            seasons: [Season](),
            loadStatus: .loading
        )
    }
}

extension SeasonsViewController.ViewState {
    func season(of episode: Episode) -> Season? {
        for season in seasonsToShow {
            guard season.episodes.contains(episode) else { continue }
            return season
        }
        return nil
    }
}

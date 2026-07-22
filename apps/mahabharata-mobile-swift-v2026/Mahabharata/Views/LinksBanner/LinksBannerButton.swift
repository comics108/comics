//
//  LinksBannerButton.swift
//  Mahabharata
//
//  Created by Aleksey Shevchenko on 03.03.2022.
//  Copyright © 2022 Iron Water Studio. All rights reserved.
//

import UIKit

extension LinksBannerButton {
    struct ViewState {
        var url: URL?
    }
}

extension LinksBannerButton.ViewState {
    static var empty: LinksBannerButton.ViewState { .init() }
}

class LinksBannerButton: UIButton {
    var viewState: ViewState = .empty
}

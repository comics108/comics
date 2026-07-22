//
//  LinksBanner.swift
//  Mahabharata
//
//  Created by Aleksey Shevchenko on 02.03.2022.
//  Copyright © 2022 Iron Water Studio. All rights reserved.
//

import UIKit

protocol LinksBannerDelegate: AnyObject {
    func topButtonClicked()
    func linkClicked(_ url: URL)
}

extension LinksBanner {
    enum Position {
        case open, close
    }
}

extension LinksBanner {
    enum Link {
        case facebook(URL, UIImage),
             instagram(URL, UIImage),
             shop(URL, UIImage),
             youtube(URL, UIImage)
    }
}

extension LinksBanner {
    struct ViewState {
        private(set) var position: LinksBanner.Position = .open
        var links: [Link] {
            [
                .shop(
                    URL(string: "https://mahabharatashop.myshopify.com")!,
                    UIImage(named: "link-banner-shop")!
                ),
                .instagram(
                    URL(string: "https://instagram.com/mahabharatagods")!,
                    UIImage(named: "link-banner-instagram")!
                ),
                .facebook(
                    URL(string: "https://www.facebook.com/mahabharatagods")!,
                    UIImage(named: "link-banner-facebook")!
                ),
                .youtube(
                    URL(string: "https://youtube.com/c/MahabharataGodsHeroes")!,
                    UIImage(named: "link-banner-youtube")!
                ),
            ]
        }
    }
}

extension LinksBanner.ViewState {
    static var empty: LinksBanner.ViewState { .init() }
}

extension LinksBanner.ViewState {
    mutating func toggle() {
        switch position {
        case .open:
            position = .close
        case .close:
            position = .open
        }
    }
}

class LinksBanner: UIView {
    var state: ViewState = .empty
    weak var delegate: LinksBannerDelegate?

    private lazy var backgroundButton: UIButton = .init()

    private lazy var topButton: UIButton = {
        UIButton(.gradientEnd)
            .corners(4)
            .clip()
    }()

    lazy var container: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 20
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        roundCorners(
            corners: [
                .topLeft,
                .topRight,
            ],
            radius: 20
        )
    }
}

extension LinksBanner {
    private func setupViews() {
        setupView()
        setupBackgroundButton()
        setupTopButton()
        setupContainer()
        activateConstraints(
            backgroundButton
                .leading().top().trailing().bottom(),
            topButton
                .width(34).height(6)
                .centerX()
                .top(8),
            container
                .pinTop(12, to: topButton)
                .centerX()
        )
        container.arrangedSubviews.forEach({
            activateConstraints($0.height(26))
        })
    }

    private func setupView() {
        backgroundColor = .gradientStart
    }

    private func setupBackgroundButton() {
        backgroundButton.addTarget(self, action: #selector(topButtonClick), for: .touchUpInside)
        addSubview(backgroundButton)
    }

    private func setupTopButton() {
        topButton.addTarget(self, action: #selector(topButtonClick), for: .touchUpInside)
        addSubview(topButton)
    }

    private func setupContainer() {
        addSubview(container)
        for link in state.links {
            let button = LinksBannerButton()
            button.imageView?.contentMode = .scaleAspectFit
            switch link {
            case .shop(let url, let image):
                button.viewState.url = url
                button.setImage(image, for: .normal)
            case .instagram(let url, let image):
                button.viewState.url = url
                button.setImage(image, for: .normal)
            case .facebook(let url, let image):
                button.viewState.url = url
                button.setImage(image, for: .normal)
            case .youtube(let url, let image):
                button.viewState.url = url
                button.setImage(image, for: .normal)
            }
            button.addTarget(self, action: #selector(linkClick(_ :)), for: .touchUpInside)
            container.addArrangedSubview(button)
        }
    }
}

extension LinksBanner {
    @objc private func topButtonClick() {
        delegate?.topButtonClicked()
    }
}

extension LinksBanner {
    @objc private func linkClick(_ sender: UIButton) {
        guard let delegate = delegate,
              let button = sender as? LinksBannerButton,
              let url = button.viewState.url else { return }
        delegate.linkClicked(url)
    }
}

extension LinksBanner {
    func animateLinks() {
        
    }
}

extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: corners,
            cornerRadii: CGSize(
                width: radius,
                height: radius
            )
        )
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

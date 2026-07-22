//
//  SeasonsScreenEpisodeCollectionViewCell.swift
//  Mahabharata
//
//  Created by Aleksey Shevchenko on 20.02.2022.
//  Copyright © 2022 Iron Water Studio. All rights reserved.
//

import UIKit

extension SeasonsScreenEpisodeCollectionViewCell {
    struct ViewState: Equatable {
        var episode: Episode
        var cta: String
        /// Protection from large images on server
        var normalSizeImageUrl: String {
            episode.image.replace("*", withValue: "944")
        }

        init(episode: Episode,cta: String) {
            self.episode = episode
            self.cta = cta
        }
    }
}

extension SeasonsScreenEpisodeCollectionViewCell.ViewState {
    static var empty: SeasonsScreenEpisodeCollectionViewCell.ViewState {
        .init(
            episode: Episode(),
            cta: ""
        )
    }
}

class SeasonsScreenEpisodeCollectionViewCell: UICollectionViewCell {
    var state: ViewState = .empty {
        didSet {
            updateAppearance()
        }
    }
    weak var delegate: SeasonsViewControllerDelegate?
    private var requestManager: MahabharataRequestManager? = nil

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 1
        return imageView
    }()

    private let titleLabel: TopAlignedLabel = {
        let label = TopAlignedLabel()
        label.numberOfLines = 0
        label.textColor = .white
        label.font = .regular(ofSize: 12)
        return label
    }()

    private let ctaButton: ProgressButton = {
        ProgressButton()
            .font(.regular(ofSize: 8))
            .color(.brown)
            .background(.sand)
            .corners(2)
            .clip()
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        requestManager?.cancelConnection()
        requestManager = nil
        imageView.image = nil
        titleLabel.text = nil
        ctaButton.progressState = .none
    }
}

extension SeasonsScreenEpisodeCollectionViewCell {
    private func setupViews() {
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        setupCtaButton()
        activateConstraints(
            imageView
                .leading(16).top(16).bottom(16)
                .width(64),

            ctaButton
                .bottom(20).trailing(20)
                .width(78).height(20),

            titleLabel
                .pinLeft(12, to: imageView)
                .top(20).trailing(20)
                .pinBottom(8, to: ctaButton)
        )
    }

    private func setupCtaButton() {
        contentView.addSubview(ctaButton)
        ctaButton.addTarget(self, action: #selector(ctaButtonClicked), for: .touchUpInside)
    }
}

extension SeasonsScreenEpisodeCollectionViewCell {
    @objc private func ctaButtonClicked() {
        delegate?.ctaClicked(self)
    }
}

extension SeasonsScreenEpisodeCollectionViewCell {
    private func updateAppearance() {
        updateImageView()
        updateTitleLabel()
        updateCta()
    }

    // MARK: - rework
    private func updateImageView() {
        guard !String.isNilOrWhiteSpace(state.episode.image) else {
            imageView.image = ImageManager.solid(color: .black, size: EpisodeCollectionViewCell.episodeCoverSize)
            return
        }
        requestManager = MahabharataRequestManager.downloadImage(
            state.normalSizeImageUrl,
            defaultImageName: nil,
            cachePath: MahabharataRequestManager.cachePath(state.episode),
            context: self,
            success: { [weak self] image in
                guard let cell = self else { return }
                cell.requestManager = nil
                guard let image = image else { return }
                cell.imageView.image = image
            }
        )
    }

    private func updateTitleLabel() {
        titleLabel.text = state.episode.name
    }

    private func updateCta() {
        ctaButton.setTitle(state.cta, for: .normal)
    }
}

extension SeasonsScreenEpisodeCollectionViewCell {
    static var reuseIdentifier: String {
        "SeasonsScreenEpisodeCollectionViewCellReuseIdentifier"
    }
    class var nibName: String {
        "SeasonsScreenEpisodeCollectionViewCell"
    }
}

extension SeasonsScreenEpisodeCollectionViewCell {
    func update(episode: Episode, bookPurchased: Bool) {
        ctaButton.progressState = Episode.getState(
            episode: episode,
            bookPurchased: bookPurchased
        )
    }
}

final class TopAlignedLabel: UILabel {
    override func drawText(in rect: CGRect) {
        super.drawText(in: .init(
            origin: .zero,
            size: textRect(
                forBounds: rect,
                limitedToNumberOfLines: numberOfLines
            ).size
        ))
    }
}

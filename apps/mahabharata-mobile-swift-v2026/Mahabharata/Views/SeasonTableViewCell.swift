//
//  SeasonsHeaderTableViewCell.swift
//  Mahabharata
//
//  Created by Roman Developer on 10/11/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

protocol SeasonTableViewCellDelegate: AnyObject {
	func seasonTableViewCellDelegateSelectedBuy(_ cell: SeasonTableViewCell)
}

extension SeasonTableViewCell {

    enum CtaButtonStyle {
        case usual, green
    }
}

extension SeasonTableViewCell {
    struct ViewState {
        var ctaButtonStyle: CtaButtonStyle?
        var season: Season?
        var ctaTitle: String?

        static var empty: ViewState {
            return ViewState()
        }
    }
}

extension SeasonTableViewCell.ViewState {
    var titleLabelText: String {
        guard let season = season else { return "" }
        return season.name.fixNewLine()
    }
    var subtitleLabelText: String {
        guard let season = season else { return "" }
        return season.episodes.isEmpty
            ? Local("Seasons.ComingSoon")
            : String.localizedStringWithFormat(
                Local("Episodes.Count"),
                season.episodes.count
            )
    }
}

class SeasonTableViewCell: ReusableTableViewCell {
    var state: ViewState = .empty {
        didSet {
            updateAppearance()
        }
    }

    var onClick: (() -> Void)?
    private var requestManager: MahabharataRequestManager? = nil

	private var panelView: UIView = {
		let view = UIView()
		view.backgroundColor = .rgba(28, 12, 25)
		view.layer.cornerRadius = 2
		view.layer.shadowColor = UIColor.black.alpha(0.36).cgColor
		view.layer.shadowOffset = CGSize(width: 0, height: 3)
		view.layer.shadowOpacity = 1
		view.layer.shadowRadius = 3
		return view
	}()
	
	private let coverView: UIView = {
		let view = UIView()
		view.layer.cornerRadius = 2
		view.clipsToBounds = true
		return view
	}()
	
	private let coverImageView = UIImageView()
	private let textView = UIView()
    private let titleLabel: UILabel = .titleLabel()
    private let subtitleLabel: UILabel = .seasonSubtitleLabel()
    private var ctaButton: UIButton = {
        UIButton(.maroon1)
            .font(UIFont.semibold(ofSize: 10))
            .color(.yellow1)
            .borderColor(.yellow1)
            .corners(4)
            .clip()
    }()

	// Enlarge click area of Buy button
	private let bigBuyButton = UIButton(type: .custom).background(.clear)
	
	private var blockBuyButtonView: UIView?

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		// Cancel image download
		self.requestManager?.cancelConnection()
		self.requestManager = nil
		self.coverImageView.image = nil
		self.unblockUI()
	}
}

// MARK: - Setup Views

extension SeasonTableViewCell {

    private func setupView() {
        selectionStyle = .none
        backgroundColor = UIColor.clear
        separatorInset = UIEdgeInsets(top: 0, left: 5000, bottom: 0, right: 0)
    }

    private func setupBtnBuy() {
        ctaButton.addTarget(self, action: #selector(ctaButtonClick), for: .touchUpInside)
        ctaButton.contentEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        ctaButton.setContentHuggingPriority(.required, for: .vertical)
        ctaButton.setContentHuggingPriority(.required, for: .vertical)
        activateConstraints(
            ctaButton.width(128)
        )
    }

    private func setupBtnBigBuy() {
        bigBuyButton.addTarget(self, action: #selector(ctaButtonClick), for: .touchUpInside)
    }

    private func setupViews() {
        setupView()
        setupBtnBuy()
        setupBtnBigBuy()

        contentView.addSubview(panelView)
        panelView.addSubviews(coverView, textView, bigBuyButton)
        coverView.addSubviews(coverImageView)
        textView.addSubviews(titleLabel, subtitleLabel, ctaButton)

        activateConstraints(
            panelView.top().leading(16).trailing(4).bottom(16).priority(999),
            coverView.dockLeft(),
            coverImageView.dockLeft().trailing(2).width(71).height(128),
            textView
                .pinLeft(16, to: coverImageView)
                .trailing(16).top().bottom(),

            titleLabel.leading().top(8).trailing(),
            subtitleLabel.pinTop(5, to: titleLabel).leading().trailing(),
            ctaButton
                .leading().trailing(>=0).bottom(8),
            bigBuyButton.edges(-7, to: ctaButton)
        )
    }

    @objc private func ctaButtonClick() {
        onClick?()
    }
}

// MARK: - Update Views

extension SeasonTableViewCell {

    private func updateAppearance() {
        guard let season = state.season else { return }
        titleLabel.text = state.titleLabelText
        subtitleLabel.text = state.subtitleLabelText

        // Setup "Buy" button. Hide it Task #21023 but keep code for case they restore it
        updateCtaButton()
        //fillBuyButton("")

        updateImgCover(season)
    }

    private func updateCtaButton() {
        guard let ctaTitle = state.ctaTitle, let ctaButtonStyle = state.ctaButtonStyle else { return }
        ctaButton.isHidden = ctaTitle.isEmpty
        ctaButton.setTitle(ctaTitle, for: .normal)
        updateCtaButton(ctaButtonStyle)
    }
    
    private func updateCtaButton(_ style: CtaButtonStyle) {
        switch style {
        case .usual: makeCtaButtonUsual()
        case .green: makeCtaButtonGreen()
        }
    }
    
    private func makeCtaButtonUsual() {
        ctaButton
            .font(.semibold(ofSize: 10))
            .color(.sand)
            .background(.brown)
            .borderColor(.brown)
            .corners(4)
            .clip()
    }
    
    private func makeCtaButtonGreen() {
        ctaButton
            .background(.darkGreen)
            .font(UIFont.semibold(ofSize: 11))
            .color(.white)
            .borderColor(.yellow1)
            .corners(4)
            .clip()
    }

    private func updateImgCover(_ season: Season) {
        if String.isNilOrWhiteSpace(season.image) {
            coverImageView.image = ImageManager.solid(
                color: .black,
                size: CGSize(
                    width: 71,
                    height: 128
                )
            )
        } else {
            self.requestManager = MahabharataRequestManager.downloadImage(
                season.image,
                defaultImageName: nil,
                cachePath: MahabharataRequestManager.cachePath(season),
                context: self,
                success: { [weak self] image in
                    guard let cell = self else { return }
                    cell.requestManager = nil
                    guard let image = image else { return }
                    cell.coverImageView.image = image
                }
            )
        }
    }
}

extension SeasonTableViewCell {

    func blockUI() {
        ctaButton.showActivityIndicator()

        // Do not allow to click twice. Do not use isUserInterectionEnabled because it will pass button click to table row
        blockBuyButtonView = UIView()
        bigBuyButton.addSubview(blockBuyButtonView!)
        activateConstraints(blockBuyButtonView!.edges())
    }

    func unblockUI() {
        ctaButton.hideActivityIndicator()

        blockBuyButtonView?.removeFromSuperview()
    }
}

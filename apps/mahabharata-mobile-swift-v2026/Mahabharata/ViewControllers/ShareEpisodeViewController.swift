//
//  ShareQuoteViewController.swift
//  Mahabharata
//
//  Created by Olga Zhegulo  on 28/03/2018.
//  Copyright © 2018 Iron Water Studio. All rights reserved.
//

import UIKit
import FirebaseAnalytics

extension ShareEpisodeViewController {

    struct ViewState: Equatable {
        var episode: Episode?
        var episodeImage: UIImage?
        var shareText: String {
            return String.localizedStringWithFormat(
                Local("Share.Episode.PromptFormat"),
                Local("Share.Link")
            )
        }
        var chapterNumber: String {
            guard let episode = episode else { return "" }
            return "\(Local("Episodes.Episode")) \(episode.order)"
        }
        var chapterName: String {
            guard let episode = episode else { return "" }
            return episode.name
        }
        var image: String {
            guard let episode = episode else { return "" }
            return episode.image
        }
    }
}

extension ShareEpisodeViewController.ViewState {
    static var empty: ShareEpisodeViewController.ViewState {
        .init(
            episode: nil
        )
    }
}

class ShareEpisodeViewController: UIViewController {

	var okBlock: ((Episode, UIImage?) -> ())?
	var cancelBlock: (() -> ())?
    private var reqMan : MahabharataRequestManager? = nil

	private let contentView: UIView = UIView().background(.maroon1).corners(2)
	private let lblTitle = UILabel(Local("Share.Episode.Title")).font(UIFont.semibold(ofSize: 22)).color(UIColor.yellow1)
	private let messageTextView: UITextView = {
		let txt = UITextView()
		txt.font = UIFont.regular(ofSize: 20)
		txt.textColor = .white
		txt.backgroundColor = .clear
		return txt
	}()
	private let vEpisodeInfo: UIView = UIView().background(.clear)
	private let coverImageView: UIImageView = {
		let img = UIImageView()
		img.layer.cornerRadius = 4.0
		img.layer.shadowColor = UIColor.black.alpha(0.5).cgColor
		img.layer.shadowOpacity = 1
		img.layer.shadowRadius = 2
		img.layer.shadowOffset = .zero
		return img
	}()
	private let lblChapterNumber = UILabel.chapterSmallLabel()
	private let lblChapterName = UILabel.titleSmallLabel()
	private lazy var btnShare: UIButton = {
		let btn = UIButton(type: .custom)
            .color(.yellow1)
            .background(.clear)
            .font(UIFont.semibold(ofSize: 14))
            .corners(4)
            .borderColor(.yellow1)
            .clip()
			.title(Local("Share.Share"))
		btn.addTarget(self, action: #selector(btnShare_Click(_:)), for: .touchUpInside)
		return btn
	}()
	private lazy var btnCancel: UIButton = {
		let btn = UIButton(type: .custom)
            .color(.yellow1)
            .background(.clear)
            .font(UIFont.semibold(ofSize: 14))
            .corners(4)
            .borderColor(.yellow1)
            .clip()
			.title(Local("Share.Cancel"))
		btn.addTarget(self, action: #selector(btnCancel_Click(_:)), for: .touchUpInside)
		return btn
	}()
	
	private var cMessageHeight: NSLayoutConstraint!

    var state: ViewState = .empty {
        didSet {
            guard oldValue != state else { return }
            updateAppearance()
        }
    }
	
	override func loadView() {
		self.view = UIView()
		
		self.view.backgroundColor = UIColor.rgba(0, 0, 0, 0.3)
		
		self.view.addSubview(self.contentView)
		self.view.addSubview(self.vEpisodeInfo)
		
		[self.lblTitle, self.messageTextView, self.vEpisodeInfo, self.btnShare, self.btnCancel].forEach(self.contentView.addSubview)
		
		[self.coverImageView, self.lblChapterNumber, self.lblChapterName].forEach(self.vEpisodeInfo.addSubview)

		if UIDevice.isIPad {
			activateConstraints(
				[self.contentView.widthItem == self.view.widthItem * 0.5],
				[self.contentView.heightItem <= self.view.heightItem * 0.5]
			)
		} else {
			activateConstraints(
				[self.contentView.topItem >= self.view.topItem + 8],
				[self.contentView.leadingItem >= self.view.leadingItem + 8],
				[self.contentView.trailingItem <= self.view.trailingItem - 8],
				[self.contentView.bottomItem <= self.view.bottomItem - 8]
			)
		}
		
		self.cMessageHeight = messageTextView.heightItem == 108
		
		activateConstraints(
			self.contentView.center(),
			
			self.lblTitle.top(24).leading(16).trailing(16),
			self.messageTextView.pinTop(16 - 6, to: self.lblTitle).leading(16 - 6).trailing(16 - 6),
			[self.cMessageHeight],
			
			self.vEpisodeInfo.pinTop(24 - 6, to: self.messageTextView).leading().trailing(),
			
			self.coverImageView.top().leading(16).width(71).height(103).bottom(16),
			self.lblChapterNumber.pinLeft(16, to: self.coverImageView).top(2).trailing(73),
			self.lblChapterName.pinTop(6, to: self.lblChapterNumber).leading(to: self.lblChapterNumber).trailing(73),

			self.btnShare.pinTop(16, to: self.vEpisodeInfo).leading(16).height(34),
			[self.btnShare.bottomItem == self.contentView.bottomItem - 24],
			self.btnCancel.pinTop(16, to: self.vEpisodeInfo).pinLeft(16, to: self.btnShare).trailing(16).bottom(to: self.btnShare).height(34).width(of: self.btnShare)
		)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Hide keyboard
		self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(_:))))
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		let textSize = messageTextView.sizeThatFits(messageTextView.frame.size)
		// 7 lines
		cMessageHeight.constant = min(textSize.height, 187)
	}
	
	// MARK: - Handlers
	@objc func btnShare_Click(_ sender: UIButton) {
        guard let episode = state.episode else { return }
		Analytics.logEvent(
            AnalyticsCustomEvents.Episode.share,
            parameters: [
                AnalyticsParameters.name: episode.name,
            ]
        )
        okBlock?(episode, state.episodeImage)
	}
	
	@objc func btnCancel_Click(_ sender: UIButton) {
		self.cancelBlock?()
	}
	
	// MARK: - Recognizer
	@objc func tapped(_ sender: UIGestureRecognizer) {
		self.messageTextView.endEditing(false)
	}
}

extension ShareEpisodeViewController {

    private func updateAppearance() {
        messageTextView.text = state.shareText
        lblChapterNumber.text = state.chapterNumber
        lblChapterName.text = state.chapterName
        updateCoverImageView()
    }

    private func updateCoverImageView() {
        if let episodeImage = state.episodeImage {
            coverImageView.image = episodeImage
        } else if String.isNilOrWhiteSpace(state.image) {
            coverImageView.image = ImageManager.solid(
                color: .black,
                size: CGSize(
                    width: 71,
                    height: 103
                )
            )
        } else if let episode = state.episode {
            reqMan = MahabharataRequestManager.downloadImage(
                state.image.replace("*", withValue: "944"), // <- Protection from large images on server
                defaultImageName: nil,
                cachePath: MahabharataRequestManager.cachePath(episode),
                context: self,
                success: { [weak self] image in
                    guard let vc =  self else { return }
                    vc.reqMan = nil
                    vc.state.episodeImage = image
                }
            )
        }
    }
}

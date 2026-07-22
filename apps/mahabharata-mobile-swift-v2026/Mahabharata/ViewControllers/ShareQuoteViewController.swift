//
//  ShareQuoteViewController.swift
//  Mahabharata
//
//  Created by Olga Zhegulo  on 28/03/2018.
//  Copyright © 2018 Iron Water Studio. All rights reserved.
//

import UIKit
import FirebaseAnalytics

class ShareQuoteViewController: UIViewController {
	
	private (set) var quote: Quote
	var okBlock: ((Quote, UIImage?) -> ())?
	var cancelBlock: (() -> ())?
	
	public var text: String {
		return txtMessage.text
	}
	
	private let contentView: UIView = UIView().background(.maroon1).corners(2)
	
	private var reqMan : MahabharataRequestManager? = nil
	
	private let lblTitle = UILabel(Local("Share.Quote.Title")).font(UIFont.semibold(ofSize: 22)).color(UIColor.yellow1)
	
	private let txtMessage: UITextView = {
		let txt = UITextView()
		txt.text = Local("Share.Quote.Prompt") + " " + Local("Share.Link")
		txt.font = UIFont.regular(ofSize: 20)
		txt.textColor = .white
		txt.backgroundColor = .clear
		return txt
	}()

	private let lblText = UILabel().font(UIFont.regular(ofSize: 20)).color(UIColor.white).lines(0).alignment(.center)

	private let imgCover: UIImageView = {
		let view = UIImageView()
		view.layer.cornerRadius = 2
		view.layer.shadowColor = UIColor.black.alpha(0.36).cgColor
		view.layer.shadowOffset = CGSize(width: 0, height: 3)
		view.layer.shadowOpacity = 1
		view.layer.shadowRadius = 3
		
		return view
	}()
	
	private lazy var btnShare: UIButton = {
		let btn = UIButton(type: .custom).color(.yellow1).background(.clear).font(UIFont.semibold(ofSize: 14)).corners(4).borderColor(.yellow1).clip()
			.title(Local("Share.Share"))
		
		btn.addTarget(self, action: #selector(btnShare_Click(_:)), for: .touchUpInside)
		
		return btn
	}()
	
	private lazy var btnCancel: UIButton = {
		let btn = UIButton(type: .custom).color(.yellow1).background(.clear).font(UIFont.semibold(ofSize: 14)).corners(4).borderColor(.yellow1).clip()
			.title(Local("Share.Cancel"))
		
		btn.addTarget(self, action: #selector(btnCancel_Click(_:)), for: .touchUpInside)
		
		return btn
	}()
	
	private var cMessageHeight: NSLayoutConstraint!
	
	//TODO: pass as argument to share block
	var quoteImage: UIImage? {
		return self.imgCover.image
	}
	
	//MARK: - init
	init(quote: Quote) {
		self.quote = quote
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func loadView() {
		self.view = UIView()
		
		self.view.backgroundColor = UIColor.rgba(0, 0, 0, 0.3)
		
		self.view.addSubview(self.contentView)
		
		[self.lblTitle, self.txtMessage, self.lblText, self.imgCover, self.btnShare, self.btnCancel].forEach(self.contentView.addSubview)

		self.cMessageHeight = txtMessage.heightItem == 108

		self.lblTitle.setContentCompressionResistancePriority(.required, for: .vertical)
		//self.imgCover.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

		if UIDevice.isIPad {
			activateConstraints(
				[self.contentView.widthItem == self.view.widthItem * 0.5],
				[self.contentView.heightItem <= self.view.heightItem * 0.5]
			)
		} else {
			activateConstraints(
				[self.contentView.topItem >= self.view.topItem + 8],
				[self.contentView.leadingItem == self.view.leadingItem + 8],
				[self.contentView.trailingItem == self.view.trailingItem - 8],
				[self.contentView.bottomItem <= self.view.bottomItem - 8]
			)
		}
		
		activateConstraints(
			self.contentView.center(),

			self.lblTitle.top(24).leading(16).trailing(16),
			self.txtMessage.pinTop(16-6, to: self.lblTitle).leading(16-6).trailing(16-6),
//			[self.txtMessage.widthItem >= ],
			[self.cMessageHeight],
			self.imgCover.pinTop(24-6, to: self.txtMessage).centerX(),
			[self.imgCover.widthItem == self.imgCover.heightItem],
			[self.imgCover.leadingItem >= self.contentView.leadingItem + 16],
			
			self.lblText.edges(to: self.imgCover),
			
			self.btnShare.pinTop(24, to: self.imgCover).leading(16).height(34),
			[self.btnShare.bottomItem == self.contentView.bottomItem - 24],
			self.btnCancel.pinTop(24, to: self.imgCover).pinLeft(16, to: self.btnShare).trailing(16).bottom(to: self.btnShare).height(34).width(of: self.btnShare)
		)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.fill(with: self.quote)
		
		//Hide keyboard
		self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(_:))))
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		let textSize = txtMessage.sizeThatFits(txtMessage.frame.size)
		//7 lines
		self.cMessageHeight.constant = min(textSize.height, 187)
	}
	
	//MARK: - Handlers
	@objc func btnShare_Click(_ sender: UIButton) {
		Analytics.logEvent(AnalyticsCustomEvents.Quote.share, parameters: [:])

		self.okBlock?(self.quote, self.quoteImage)
	}
	
	@objc func btnCancel_Click(_ sender: UIButton) {
		self.cancelBlock?()
	}
	
	//MARK - Recognizer
	@objc func tapped(_ sender: UIGestureRecognizer) {
		self.txtMessage.endEditing(false)
	}

	// MARK: - Functionality
	private func fill(with quote: Quote) {
		//For case when image is missing
		self.lblText.text = quote.name

		self.reqMan = MahabharataRequestManager.downloadImage(
			quote.image.replace("*", withValue: "944"),	//Protection from large images on server
			defaultImageName: nil,
			cachePath: MahabharataRequestManager.cachePath(quote),
			context: self,
			success: { [weak self] (image) in
				guard let self = self else { return }
				self.reqMan = nil

				if let img = image {
					self.imgCover.image = img
				}
		})
	}
}

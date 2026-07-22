//
//  ComicsBottomView.swift
//  Mahabharata
//
//  Created by Olga Zhegulo  on 19/03/2018.
//  Copyright © 2018 Iron Water Studio. All rights reserved.
//

import UIKit

protocol ComicsBottomViewDelegate: class {
	func comicsBottomViewWillBuy(_ view: ComicsBottomView)
}

class ComicsBottomView: UIView {
	weak var delegate: ComicsBottomViewDelegate?

	private var reqMan : MahabharataRequestManager? = nil
	
	private let vBackground = GradientView(gradientStart: UIColor.rgba(31,25,31,0), gradientEnd: UIColor.rgba(15,7,15,1))//
		.background(.clear)
	
	private let imgCover: UIImageView = {
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
	private let btnBuy = UIButton.greenButton()
	private var csBuyButtonHeight: [NSLayoutConstraint] = []
	private var csBuyButtonTop: [NSLayoutConstraint] = []

	override init(frame: CGRect) {
		super.init(frame: frame)
		
		self.backgroundColor = .clear
		
		self.addSubviews(vBackground, imgCover, lblChapterNumber, lblChapterName, btnBuy)
		
		self.btnBuy.addTarget(self, action: #selector(btnBuy_Click(_:)), for: .touchUpInside)
		
		csBuyButtonHeight = btnBuy.height(35)
		csBuyButtonTop = btnBuy.pinTop(15, to: self.lblChapterName)
		
		activateConstraints(
			vBackground.edges(),
			
			imgCover.width(71).height(103).top(32).leading(32).bottom(23),
			csBuyButtonHeight,
			csBuyButtonTop,
			btnBuy.pinLeft(16, to: imgCover).trailing(33).bottom(29),
			lblChapterName.pinBottom(8, to: btnBuy).pinLeft(>=16, to: self.imgCover).trailing(39),
			lblChapterNumber.pinBottom(7, to: lblChapterName).top(>=34).pinLeft(>=16, to: self.imgCover).trailing(43)
		)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func hitTest(_ point: CGPoint,
						  with event: UIEvent?) -> UIView? {
		
		if self.btnBuy.point(inside: self.convert(point, to: self.btnBuy), with: event) {
			return self.btnBuy
		} else {
			return nil
		}
	}

	//MARK: - Method
	func fill(episode: Episode?, bookPurchased: Bool, buyTitle: String) {
		if let episode = episode {
			self.lblChapterNumber.text = "\(Local("Episodes.Episode")) \(episode.order)"
			self.lblChapterName.text = episode.name
			fillBuyButton(buyTitle, bookPurchased: bookPurchased)
			
			if !String.isNilOrWhiteSpace(episode.image) {
				self.reqMan = MahabharataRequestManager.downloadImage(
					episode.image.replace("*", withValue: "944"),	//Protection from large images on server
					defaultImageName: nil,
					cachePath: MahabharataRequestManager.cachePath(episode),
					context: self,
					success: { [weak self] (image) in
						guard let self = self else { return }
						self.reqMan = nil
						
						if let img = image {
							self.imgCover.image = img
						}
				})
			} else {
				self.imgCover.image = ImageManager.solid(color: .black, size: CGSize(width: 71, height: 103))
			}
		} else {
			self.lblChapterNumber.text = nil
			self.lblChapterName.text = nil
			self.btnBuy.isHidden = true
		}
	}
	
	func fillBuyButton(_ title: String, bookPurchased: Bool) {
		btnBuy.isHidden = title.isEmpty
		csBuyButtonHeight.first?.constant = btnBuy.isHidden ? 0 : 35
		csBuyButtonTop.first?.constant = btnBuy.isHidden ? 0 : 15
		btnBuy.setTitle(title, for: .normal)
		btnBuy.isUserInteractionEnabled = !bookPurchased
	}

	// MARK: - Handlers
	@objc
	func btnBuy_Click(_ sender: UIButton) {
		self.delegate?.comicsBottomViewWillBuy(self)
	}
	
	func blockUI() {
		btnBuy.isUserInteractionEnabled = false
		btnBuy.showActivityIndicator()
	}
	
	func unblockUI() {
		btnBuy.isUserInteractionEnabled = true
		btnBuy.hideActivityIndicator()
	}
}


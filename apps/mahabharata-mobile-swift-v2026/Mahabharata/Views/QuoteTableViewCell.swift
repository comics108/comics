//
//  QuoteTableViewCell.swift
//  Mahabharata
//
//  Created by Olga Zhegulo  on 28/03/2018.
//  Copyright © 2018 Iron Water Studio. All rights reserved.
//

import UIKit

protocol QuoteTableViewCellDelegate: class {
	func quoteTableViewCellDidShare(_ cell: QuoteTableViewCell, quote: Quote)
}

class QuoteTableViewCell: ReusableTableViewCell {

	private var quote: Quote?
	private weak var delegate: QuoteTableViewCellDelegate?

	private var reqMan : MahabharataRequestManager? = nil
	
	private let imgPhoto: UIImageView = {
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
			.title(Local("Quotes.Share"))
		
		btn.addTarget(self, action: #selector(btnShare_Click(_:)), for: .touchUpInside)
		
		return btn
	}()
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		self.selectionStyle = .none
		self.backgroundColor = UIColor.clear
		self.separatorInset = UIEdgeInsets(top: 0, left: 5000, bottom: 0, right: 0)
		
		self.contentView.addSubview(self.imgPhoto)
		self.contentView.addSubview(self.btnShare)
		
		activateConstraints(
			self.imgPhoto.top().leading(16).trailing(16),
			[self.imgPhoto.widthItem == self.imgPhoto.heightItem],
			self.imgPhoto.top().leading(16).trailing(16),

			self.btnShare.pinTop(16, to: self.imgPhoto).height(34).centerX(),
			UIDevice.isIPad ?
				[self.btnShare.widthItem == self.contentView.widthItem * 0.5] :
				self.btnShare.leading(70).trailing(70),
			[self.btnShare.bottomItem == self.contentView.bottomItem - 32 ~ 750]
		)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		//Cancel image download
		self.reqMan?.cancelConnection()
		self.reqMan = nil
		
		self.imgPhoto.image = nil
	}
	
	// MARK: - Functionality
	func fill(with quote: Quote, delegate: QuoteTableViewCellDelegate) {
		self.quote = quote
		self.delegate = delegate
		
		self.reqMan = MahabharataRequestManager.downloadImage(
			quote.image.replace("*", withValue: "944"),	//Protection from large images on server
			defaultImageName: nil,
			cachePath: MahabharataRequestManager.cachePath(quote),
			context: self,
			success: { [weak self] (image) in
				guard let self = self else { return }
				self.reqMan = nil
				
				if let img = image {
					self.imgPhoto.image = img
				}
		})
	}
	
	@objc func btnShare_Click(_ sender: UIButton) {
		if let quote = self.quote {
			self.delegate?.quoteTableViewCellDidShare(self, quote: quote)
		}
	}
	
}

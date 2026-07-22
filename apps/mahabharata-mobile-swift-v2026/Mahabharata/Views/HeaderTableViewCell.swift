//
//  HeaderTableViewCell.swift
//  Mahabharata
//
//  Created by Roman Developer on 10/11/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

class HeaderTableViewCell: ReusableTableViewCell {

	internal let lblHeader = UILabel.headerLabel()
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		self.selectionStyle = .none
		self.backgroundColor = UIColor.clear
		self.separatorInset = UIEdgeInsets(top: 0, left: 5000, bottom: 0, right: 0)
		
		self.contentView.addSubview(self.lblHeader)
		
		activateConstraints(
			self.lblHeader.centerXItem == self.contentView.centerXItem,
			self.lblHeader.topItem == self.contentView.topItem + 32,
			self.lblHeader.bottomItem == self.contentView.bottomItem - 32
		)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func fill(with title: String) {
		self.lblHeader.text = title
	}
}

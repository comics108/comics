//
//  UITableViewCell+Reuse.swift
//  SecurityApp
//
//  Created by Stanislav Grinberg on 16/06/2017.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit
import ObjectiveC

protocol ReusableTableViewCellProtocol: NSObjectProtocol {
	static var reuseID: String { get }
	
	static func register(for tableView: UITableView)
}

extension ReusableTableViewCellProtocol {
	static var reuseID: String {
		return NSStringFromClass(self)
	}
	
	static func register(for tableView: UITableView) {
		tableView.register(self, forCellReuseIdentifier: reuseID)
	}
}

extension UITableView {
	
	func dequeue<CellType: ReusableTableViewCellProtocol>(for indexPath: IndexPath) -> CellType {
		return dequeueReusableCell(withIdentifier: CellType.reuseID, for: indexPath) as! CellType
	}
	
}

class ReusableTableViewCell: UITableViewCell, ReusableTableViewCellProtocol {}

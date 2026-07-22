//
//  UICollectionViewCell+Reuse.swift
//  UICollectionViewCell+Reuse
//
//  Created by Stanislav Grinberg on 16/06/2017.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit
import ObjectiveC

protocol ReusableCollectionViewCellProtocol: NSObjectProtocol {
	static var reuseID: String { get }
	
	static func register(for collectionView: UICollectionView)
}

extension ReusableCollectionViewCellProtocol {
	static var reuseID: String {
		return NSStringFromClass(self)
	}
	
	static func register(for collectionView: UICollectionView) {
		collectionView.register(self, forCellWithReuseIdentifier: reuseID)
	}
}

extension UICollectionView {
	func dequeue<CellType: ReusableCollectionViewCellProtocol>(for indexPath: IndexPath) -> CellType {
		return dequeueReusableCell(withReuseIdentifier: CellType.reuseID, for: indexPath) as! CellType
	}
	
	func dequeue<CellType: ReusableCollectionViewCell>(for indexPath: IndexPath) -> CellType {
		return dequeueReusableCell(withReuseIdentifier: CellType.reuseID, for: indexPath) as! CellType
	}
}

class ReusableCollectionViewCell: UICollectionViewCell, ReusableCollectionViewCellProtocol {}

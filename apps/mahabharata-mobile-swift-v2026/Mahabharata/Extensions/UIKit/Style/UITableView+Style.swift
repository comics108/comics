//
//  UITableView+Style.swift
//  Neftmagistral
//
//  Created by  Ilya.Udovenko on 03/09/2018.
//  Copyright © 2018 Iron Water Studio. All rights reserved.
//

import UIKit

extension UITableView {

    // MARK: - Experimental
    
    @discardableResult
    func bkg(_ color: UIColor) -> Self {
        self.backgroundColor = color
        return self
    }
    
    @discardableResult
    func header(_ view: UIView = UIView()) -> Self {
        self.tableHeaderView = view
        return self
    }
    
    @discardableResult
    func footer(_ view: UIView = UIView()) -> Self {
        self.tableFooterView = view
        return self
    }
    
    @discardableResult
    func row(_ height: CGFloat? = nil, estimated: CGFloat? = nil) -> Self {
        if let height = height {
            self.rowHeight = height
        } else  {
			self.rowHeight = UITableView.automaticDimension
        }
        
        if let estimated = estimated {
            self.estimatedRowHeight = estimated
        }
        return self
    }
}



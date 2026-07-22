//
//  ProgressButton.swift
//  Mahabharata
//
//  Created by Roman Developer on 11/10/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

class ProgressButton: UIButton {
	var vProgress: UIView?
	var csProgressWidth: NSLayoutConstraint!
	
	var progressState: Episode.ProgressState = .none {
		didSet {
			applyState(progressState)
		}
	}
	
	func applyState(_ state: Episode.ProgressState) {
        // temporary or not
        background(.yellow1).color(.maroon1).title(Local("Episodes.Read"))
        removeProgress()

		switch state {
		case .none:
			title("")
			removeProgress()
		case .soon:
			self.background(.clear).color(.yellow1).title(Local("Episodes.Soon"))
		case .free:
			// Set colors and title for Free
            background(.yellow1).color(.maroon1).title(Local("Episodes.Read"))
			// Remove progress
			removeProgress()
		case .shouldPurchase(let price):
			// Set colors for bought + title with price
			self.background(.clear).color(.yellow1).title(price)
			// Remove progress
			removeProgress()
		case .downloading(let downloadInfo):
			// Set color for text
			background(.maroon1).color(.white)
			// Show progress bar
			//print("set progress for \(episode.name) \(downloadInfo.progress)")
			setProgress(downloadInfo: downloadInfo)
		case .bought:
			background(.clear).color(.yellow1).title(Local("Episodes.Bought"))
		case .unpacking:
			background(.clear).color(.white).title(Local("Episodes.Unpacking"))
		case .downloaded:
			// Set title and color
			background(.yellow1).color(.maroon1).title(Local("Episodes.Read"))
			// Remove progress bar
			removeProgress()
		}
	}
	
	private func setProgress(downloadInfo: DownloadInfo) {
		let progress = downloadInfo.progress
		
		//Progress view
		if let vProgress = vProgress {
			vProgress.background(.yellow1).alpha(0.8)
		} else {
			vProgress = UIView().background(.yellow1).alpha(0.8)
			insertSubview(self.vProgress!, at: 0)
		}
		vProgress?.frame = CGRect(x: 0, y: 0, width: self.frame.size.width * progress, height: self.frame.size.height)
		
		//Percents
		title("\(Int(progress * 100)) %")
		
		addShadowFor(view: self.titleLabel!)
	}
	
	private func removeProgress() {
		vProgress?.removeFromSuperview()
		vProgress = nil
		removeShadowFor(view: self.titleLabel!)
	}
	
	private func addShadowFor(view: UIView) {
		view.layer.shadowColor = UIColor.black.alpha(0.68).cgColor
		view.layer.shadowRadius = 2
		view.layer.shadowOpacity = 1
		view.layer.shadowRadius = 2
		view.layer.masksToBounds = false
	}
	
	private func removeShadowFor(view: UIView) {
		view.layer.shadowRadius = 0
		view.layer.shadowOpacity = 0
	}
}

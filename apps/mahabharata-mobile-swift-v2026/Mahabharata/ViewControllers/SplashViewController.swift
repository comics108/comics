//
//  SplashViewController.swift
//  Mahabharata
//
//  Created by Olga Zhegulo on 31/10/2019.
//  Copyright © 2019 Iron Water Studio. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {
	override func loadView() {
		self.view = UIView()
		
		//Because launch screen has trait variations for regular * regular and other
		let isIPad = UIScreen.main.traitCollection.horizontalSizeClass == .regular && UIScreen.main.traitCollection.verticalSizeClass == .regular
		
		let imgBackground = UIImageView(image: UIImage(named: isIPad ? "splash_bg_ipad-12,9.png" : "splash_bg.png")).contentMode(.scaleAspectFill)
		let imgLogo = UIImageView(image: UIImage(named: "splash_icon.png"))
		
		self.view.addSubviews(imgBackground, imgLogo)
		
		activateConstraints(
			imgBackground.bottom(safe: false).centerX().width(isIPad ? 1024 : 414).height(isIPad ? 1366 : 896),
			imgLogo.top(197, safe: true).centerX()
		)
	}
}

//
//  SoundStateView.swift
//  Mahabharata
//
//  Created by Olga Zhegulo  on 22/03/2018.
//  Copyright © 2018 Iron Water Studio. All rights reserved.
//

import UIKit

class SoundStateView: UIView {

	private let imgIcon = UIImageView()
	
	var soundOn: Bool {
		didSet {
			fillSoundOn(soundOn: soundOn)
		}
	}
	
	init(soundOn: Bool) {
		self.soundOn = soundOn
		
		super.init(frame: .zero)
		
		self.addSubview(self.imgIcon)
		
		activateConstraints(
			self.imgIcon.edges()
		)
		
		self.fillSoundOn(soundOn: soundOn)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func fillSoundOn(soundOn: Bool) {
		self.imgIcon.image = soundOn ? UIImage(named: "icon_sound_on.png") : UIImage(named: "icon_sound_off.png")
	}
}
